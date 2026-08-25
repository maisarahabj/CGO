import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../home/widgets/home_spline_map.dart';
import '../controllers/admin_navigation_controller.dart';
import '../models/edge_model.dart';

/// Administrator interface for temporarily opening and closing graph edges.
///
/// Supabase `edges.is_active` is the availability source of truth. Administrators
/// can select an existing graph edge either by tapping two Spline nodes or by
/// choosing the corresponding accessible route card.
class AdminManageNavigationScreen extends StatefulWidget {
  const AdminManageNavigationScreen({required this.pageTitle, super.key});

  final String pageTitle;

  @override
  State<AdminManageNavigationScreen> createState() =>
      _AdminManageNavigationScreenState();
}

class _AdminManageNavigationScreenState
    extends State<AdminManageNavigationScreen> {
  late final AdminNavigationController _controller;
  final TextEditingController _searchController = TextEditingController();

  String? _selectedEdgeId;
  String? _firstSelectedNodeId;
  String _previewFloor = 'L9';
  int _previewSelectionRequest = 0;

  EdgeModel? get _selectedEdge => _controller.routeById(_selectedEdgeId);

  @override
  void initState() {
    super.initState();
    _controller = AdminNavigationController();
    _controller.setSelectedFloor(_previewFloor);
    unawaited(_controller.loadRouteSegments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _setFloorFilter(String floor) {
    _controller.setSelectedFloor(floor);

    if (floor == _previewFloor) return;

    setState(() {
      _previewFloor = floor;
      _previewSelectionRequest += 1;
      _firstSelectedNodeId = null;
      _selectedEdgeId = null;
    });
  }

  void _refreshCamera() {
    setState(() {
      _previewSelectionRequest += 1;
    });
  }

  void _handleNodeSelected(String nodeId) {
    final selectedNode = _controller.nodeById(nodeId);

    if (selectedNode == null) {
      _showMessage(
        'The map node $nodeId was not found in the Supabase navigation graph.',
        isError: true,
      );
      return;
    }

    final firstNode = _firstSelectedNodeId;

    if (firstNode == null) {
      debugPrint('Admin map selection: first-node=$nodeId');
      setState(() {
        _firstSelectedNodeId = nodeId;
        _selectedEdgeId = null;
      });
      return;
    }

    if (firstNode == nodeId) {
      debugPrint('Admin map selection: cancelled-node=$nodeId');
      setState(() {
        _firstSelectedNodeId = null;
        _selectedEdgeId = null;
      });
      return;
    }

    debugPrint('Admin map selection: second-node=$nodeId');
    final edge = _controller.routeBetweenNodes(firstNode, nodeId);

    if (edge == null) {
      debugPrint(
        'Admin map selection: no-edge-between=$firstNode,$nodeId',
      );
      _showMessage(
        '$firstNode and $nodeId are not directly connected. '
        'Select another node connected to $firstNode.',
        isError: true,
      );
      return;
    }

    debugPrint('Admin map selection: edge=${edge.edgeId}');
    setState(() {
      _firstSelectedNodeId = null;
      _selectedEdgeId = edge.edgeId;
    });
  }

  void _selectRoute(EdgeModel edge) {
    final floors = _controller.routeFloors(edge);
    final nextPreviewFloor = floors.isEmpty ? _previewFloor : floors.first;

    setState(() {
      _selectedEdgeId = edge.edgeId;
      _firstSelectedNodeId = null;
      _previewFloor = nextPreviewFloor;
      if (_controller.selectedFloor != nextPreviewFloor) {
        _controller.setSelectedFloor(nextPreviewFloor);
        _previewSelectionRequest += 1;
      }
    });
  }

  Set<String> _visiblePreviewFloors(EdgeModel? edge) {
    if (edge == null) return <String>{_previewFloor};

    final edgeFloors = _controller.routeFloors(edge);
    return edgeFloors.isEmpty ? <String>{_previewFloor} : edgeFloors.toSet();
  }

  Future<void> _manageSelectedRoute() async {
    final edge = _selectedEdge;
    if (edge == null || _controller.isSaving) return;

    final request = await showDialog<_RouteStatusRequest>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _RouteStatusDialog(
        routeName: _controller.routeNameForEdge(edge),
        routeFloor: _controller.routeFloorLabel(edge),
        currentlyOpen: edge.isActive,
      ),
    );

    if (!mounted || request == null) return;

    final succeeded = await _controller.updateRouteAvailability(
      edge: edge,
      isActive: request.isActive,
      closureReason: request.isActive ? null : request.reason,
    );

    if (!mounted) return;

    if (!succeeded) {
      _showMessage(
        _controller.errorMessage ?? 'Unable to update this route segment.',
        isError: true,
      );
      return;
    }

    final action = request.isActive ? 'reopened' : 'closed';
    final reason = request.isActive ? '' : ' Reason: ${request.reason}.';
    _showMessage(
      '${_controller.routeNameForEdge(edge)} was $action.$reason',
      isError: false,
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? _MapColors.error : _MapColors.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _CampusGoPageHeader(
                title: widget.pageTitle,
                onBackPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Column(
                      children: [
                        Expanded(child: _buildContent()),
                        _BottomManageBar(
                          isLoading: _controller.isSaving,
                          onPressed:
                              _selectedEdge == null || _controller.isSaving
                              ? null
                              : _manageSelectedRoute,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_controller.isLoading && _controller.routeSegments.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _MapColors.blue),
      );
    }

    if (_controller.errorMessage != null &&
        _controller.routeSegments.isEmpty) {
      return _MessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to load routes',
        message: _controller.errorMessage!,
        actionLabel: 'Try again',
        onAction: _controller.loadRouteSegments,
      );
    }

    final routes = _controller.filteredRouteSegments;
    final selectedEdge = _selectedEdge;

    final orderedRoutes = <EdgeModel>[
      if (selectedEdge != null) selectedEdge,
      ...routes.where((edge) => edge.edgeId != selectedEdge?.edgeId),
    ];

    return Column(
      children: [
        Expanded(
          flex: 6,
          child: _RouteMapPreview(
            selectedEdge: selectedEdge,
            selectedFloor: _previewFloor,
            selectionRequest: _previewSelectionRequest,
            visibleFloorNames: _visiblePreviewFloors(selectedEdge),
            onNodeSelected: _handleNodeSelected,
          ),
        ),
        Container(
          color: const Color(0xFFE8E8E8),
          padding: const EdgeInsets.fromLTRB(10, 7, 8, 11),
          child: SizedBox(
            height: 38,
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _refreshCamera,
                  icon: const Icon(Icons.refresh_rounded, size: 15),
                  label: const Text('Refresh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _MapColors.darkText,
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFD7DFE4)),
                    padding: const EdgeInsets.symmetric(horizontal: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (final floor
                          in AdminNavigationController.campusFloors)
                        _FloorFilterChip(
                          label: floor,
                          isSelected: _previewFloor == floor,
                          onPressed: () => _setFloorFilter(floor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _RoundedSearchField(
            controller: _searchController,
            onChanged: _controller.setSearchQuery,
            onClear: () {
              _searchController.clear();
              _controller.setSearchQuery('');
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 6),
          child: Row(
            children: [
              Icon(
                _firstSelectedNodeId == null
                    ? Icons.touch_app_outlined
                    : Icons.linear_scale_rounded,
                size: 15,
                color: _MapColors.blue,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _firstSelectedNodeId == null
                      ? 'Tap two connected green nodes or select a route below.'
                      : 'Select another node connected to '
                            '$_firstSelectedNodeId.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10.5,
                    color: _MapColors.mutedText,
                  ),
                ),
              ),
              if (_controller.closedRouteCount > 0)
                Text(
                  '${_controller.closedRouteCount} closed',
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: _MapColors.error,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          flex: 3,
          child: orderedRoutes.isEmpty
              ? const Center(
                  child: Text(
                    'No matching routes on this floor.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: _MapColors.mutedText,
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: _MapColors.blue,
                  onRefresh: _controller.loadRouteSegments,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    itemCount: orderedRoutes.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final edge = orderedRoutes[index];

                      return _RouteSegmentCard(
                        edge: edge,
                        routeName: _controller.routeNameForEdge(edge),
                        endpointSummary: _controller.routeEndpointSummary(edge),
                        floorLabel: _controller.routeFloorLabel(edge),
                        typeLabel: _controller.routeTypeLabel(edge),
                        isSelected: edge.edgeId == _selectedEdgeId,
                        onPressed: () => _selectRoute(edge),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _CampusGoPageHeader extends StatelessWidget {
  const _CampusGoPageHeader({
    required this.title,
    required this.onBackPressed,
  });

  final String title;
  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(6, 5, 6, 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EDF0))),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBackPressed,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: _MapColors.deepBlue,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text.rich(
                  TextSpan(
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                    children: [
                      TextSpan(
                        text: 'Campus',
                        style: TextStyle(color: _MapColors.brandPurple),
                      ),
                      TextSpan(
                        text: 'GO',
                        style: TextStyle(color: _MapColors.brandRed),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _MapColors.deepBlue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onBackPressed,
            icon: const Icon(
              Icons.close_rounded,
              size: 25,
              color: _MapColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundedSearchField extends StatelessWidget {
  const _RoundedSearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 14,
        color: _MapColors.darkText,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        hintText: 'Search room or route ...',
        hintStyle: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 13,
          color: Color(0xFF94A0A8),
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 22,
          color: _MapColors.mutedText,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: _MapColors.mutedText,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: const BorderSide(color: Color(0xFF7EAED0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: const BorderSide(color: Color(0xFF7EAED0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(27),
          borderSide: const BorderSide(color: _MapColors.blue, width: 1.4),
        ),
      ),
    );
  }
}

class _FloorFilterChip extends StatelessWidget {
  const _FloorFilterChip({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Material(
        color: isSelected ? _MapColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 37),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? _MapColors.blue
                    : const Color(0xFFCAD8E0),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _MapColors.darkText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteMapPreview extends StatelessWidget {
  const _RouteMapPreview({
    required this.selectedEdge,
    required this.selectedFloor,
    required this.selectionRequest,
    required this.visibleFloorNames,
    required this.onNodeSelected,
  });

  final EdgeModel? selectedEdge;
  final String selectedFloor;
  final int selectionRequest;
  final Set<String> visibleFloorNames;
  final ValueChanged<String> onNodeSelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE8E8E8),
      child: HomeSplineMap(
        selectedFloor: selectedFloor,
        selectionRequest: selectionRequest,
        visibleRouteEdgeIds: selectedEdge == null
            ? const <String>{}
            : <String>{selectedEdge!.edgeId},
        visibleFloorNames: visibleFloorNames,
        enableNodeSelection: true,
        onNodeSelected: onNodeSelected,
      ),
    );
  }
}

class _RouteSegmentCard extends StatelessWidget {
  const _RouteSegmentCard({
    required this.edge,
    required this.routeName,
    required this.endpointSummary,
    required this.floorLabel,
    required this.typeLabel,
    required this.isSelected,
    required this.onPressed,
  });

  final EdgeModel edge;
  final String routeName;
  final String endpointSummary;
  final String floorLabel;
  final String typeLabel;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: isSelected ? _MapColors.blue : const Color(0xFFE1EAF0),
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 11,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _RouteFloorBadge(floorLabel: floorLabel),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            routeName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: _MapColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            endpointSummary,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              height: 1.3,
                              color: _MapColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusPill(isOpen: edge.isActive),
                  ],
                ),
                if (!edge.isActive &&
                    edge.closureReason?.trim().isNotEmpty == true) ...[
                  const SizedBox(height: 9),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 56),
                      child: Text(
                        'Reason: ${edge.closureReason}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _MapColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 11),
                Row(
                  children: [
                    const SizedBox(width: 56),
                    _InfoChip(
                      icon: _iconForEdge(edge),
                      label: typeLabel,
                      color: _MapColors.blue,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: _InfoChip(
                        icon: edge.isAccessible
                            ? Icons.accessible_forward_rounded
                            : Icons.do_not_disturb_alt_rounded,
                        label: edge.isAccessible
                            ? 'OKU accessible'
                            : 'Not OKU accessible',
                        color: edge.isAccessible
                            ? _MapColors.success
                            : _MapColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteFloorBadge extends StatelessWidget {
  const _RouteFloorBadge({required this.floorLabel});

  final String floorLabel;

  @override
  Widget build(BuildContext context) {
    final primaryFloor = floorLabel.split('–').first;

    return Container(
      constraints: const BoxConstraints(minWidth: 45, minHeight: 45),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: _floorColor(primaryFloor),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Text(
        floorLabel,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOpen});

  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final color = isOpen ? _MapColors.success : _MapColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'Open' : 'Closed',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomManageBar extends StatelessWidget {
  const _BottomManageBar({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 11, 17, 13),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EDF0))),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(27),
          gradient: LinearGradient(
            colors: onPressed == null
                ? const <Color>[Color(0xFFB7BFC7), Color(0xFFB7BFC7)]
                : const <Color>[
                    Color(0xFF3235BD),
                    Color(0xFF7D2C87),
                    Color(0xFFFF2A0A),
                  ],
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: isLoading
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      color: Colors.white,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.tune_rounded, size: 20),
                      SizedBox(width: 7),
                      Text(
                        'Manage selected route',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _RouteStatusDialog extends StatefulWidget {
  const _RouteStatusDialog({
    required this.routeName,
    required this.routeFloor,
    required this.currentlyOpen,
  });

  final String routeName;
  final String routeFloor;
  final bool currentlyOpen;

  @override
  State<_RouteStatusDialog> createState() => _RouteStatusDialogState();
}

class _RouteStatusDialogState extends State<_RouteStatusDialog> {
  static const List<String> _closureReasons = <String>[
    'Maintenance work',
    'Safety issue',
    'Cleaning in progress',
    'Temporary obstruction',
    'Other operational reason',
  ];

  static const List<String> _reopeningReasons = <String>[
    'Maintenance completed',
    'Safety check completed',
    'Obstruction removed',
    'Route inspected and usable',
    'Other operational reason',
  ];

  late String _selectedReason;

  bool get _nextIsActive => !widget.currentlyOpen;

  List<String> get _reasons =>
      _nextIsActive ? _reopeningReasons : _closureReasons;

  @override
  void initState() {
    super.initState();
    _selectedReason = _reasons.first;
  }

  @override
  Widget build(BuildContext context) {
    final actionColor = _nextIsActive ? _MapColors.success : _MapColors.error;
    final action = _nextIsActive ? 'reopen' : 'close';

    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 5),
      actionsPadding: const EdgeInsets.fromLTRB(15, 5, 15, 14),
      title: Text(
        '${_nextIsActive ? 'Reopen' : 'Close'} route?',
        style: const TextStyle(
          fontFamily: 'Raleway',
          fontSize: 21,
          fontWeight: FontWeight.w800,
          color: _MapColors.deepBlue,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.routeName,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _MapColors.darkText,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.routeFloor,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: _MapColors.mutedText,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _nextIsActive
                    ? 'This segment will become available to the next route '
                        'calculation.'
                    : 'This segment will be excluded from the next route '
                        'calculation.',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  height: 1.4,
                  color: actionColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reason',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _MapColors.darkText,
              ),
            ),
            const SizedBox(height: 7),
            DropdownButtonFormField<String>(
              initialValue: _selectedReason,
              isExpanded: true,
              items: _reasons
                  .map(
                    (reason) => DropdownMenuItem<String>(
                      value: reason,
                      child: Text(
                        reason,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: _MapColors.darkText,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (reason) {
                if (reason != null) setState(() => _selectedReason = reason);
              },
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF7EAED0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF7EAED0)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _nextIsActive
                  ? 'Reopening the route clears its previous closure reason.'
                  : 'This reason will be saved with the closed route.',
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10.5,
                height: 1.35,
                color: _MapColors.mutedText,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _RouteStatusRequest(
                isActive: _nextIsActive,
                reason: _selectedReason,
              ),
            );
          },
          style: FilledButton.styleFrom(
            backgroundColor: actionColor,
            foregroundColor: Colors.white,
          ),
          child: Text('Confirm $action'),
        ),
      ],
    );
  }
}

class _RouteStatusRequest {
  const _RouteStatusRequest({
    required this.isActive,
    required this.reason,
  });

  final bool isActive;
  final String reason;
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 43, color: _MapColors.blue),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _MapColors.deepBlue,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                height: 1.4,
                color: _MapColors.mutedText,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 13),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _MapColors.blue,
                  side: const BorderSide(color: _MapColors.blue),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MapColors {
  static const Color blue = Color(0xFF2A77B4);
  static const Color deepBlue = Color(0xFF115388);
  static const Color brandPurple = Color(0xFF38358E);
  static const Color brandRed = Color(0xFFFF0000);
  static const Color darkText = Color(0xFF26333C);
  static const Color mutedText = Color(0xFF76828B);
  static const Color success = Color(0xFF278746);
  static const Color error = Color(0xFFBC373E);
}

IconData _iconForEdge(EdgeModel edge) {
  switch (edge.edgeType?.trim().toLowerCase()) {
    case 'elevator':
    case 'lift':
      return Icons.elevator_rounded;
    case 'stairs':
    case 'staircase':
      return Icons.stairs_rounded;
    case 'classroom':
      return Icons.meeting_room_outlined;
    case 'office':
      return Icons.business_center_outlined;
    case 'washroom':
      return Icons.wc_rounded;
    case 'auditorium':
      return Icons.co_present_outlined;
    case 'facility':
      return Icons.room_preferences_outlined;
    default:
      return Icons.route_rounded;
  }
}

Color _floorColor(String floor) {
  switch (floor.toUpperCase()) {
    case 'G':
      return const Color(0xFF168D79);
    case 'L1':
      return const Color(0xFF4F80C7);
    case 'L3':
      return const Color(0xFF775DCA);
    case 'L6':
      return const Color(0xFFBD3AA9);
    case 'L8':
      return const Color(0xFF2A77B4);
    case 'L9':
      return const Color(0xFF4262A6);
    default:
      return const Color(0xFF87939D);
  }
}
