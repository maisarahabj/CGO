import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/app_routes.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/database_tables.dart';
import '../../../shared/widgets/campus_navigation_drawer.dart';
import '../models/node_model.dart';
import '../models/visit_history_model.dart';

class VisitHistoryScreen extends StatefulWidget {
  const VisitHistoryScreen({super.key});

  @override
  State<VisitHistoryScreen> createState() => _VisitHistoryScreenState();
}

class _VisitHistoryScreenState extends State<VisitHistoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient _client = Supabase.instance.client;

  List<_VisitHistoryEntry> _entries = const [];
  bool _isLoading = true;
  bool _isAccessibilityEnabled = false;
  String? _errorMessage;

  static const Color _headingBlue = Color(0xFF2A77B4);
  static const Color _headingOrange = Color(0xFFF76B00);
  static const Color _bannerInk = Color(0xFF3C5F7B);
  static const Color _sectionHeadingBlue = Color(0xFF115388);

  @override
  void initState() {
    super.initState();
    _loadVisitHistory();
  }

  Future<void> _loadVisitHistory() async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Sign in to view your visit history.';
      });

      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final historyRows = await _client
          .from(DatabaseTables.visitHistories)
          .select('visit_id, user_id, destination_node_id, visited_at')
          .eq('user_id', currentUser.id)
          .order('visited_at', ascending: false);

      final visits = historyRows
          .map(
            (row) => VisitHistoryModel.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList(growable: false);

      final destinationNodeIds = visits
          .map((visit) => visit.destinationNodeId?.trim())
          .whereType<String>()
          .where((nodeId) => nodeId.isNotEmpty)
          .toSet()
          .toList(growable: false);

      final nodesById = <String, NodeModel>{};

      if (destinationNodeIds.isNotEmpty) {
        final nodeRows = await _client
            .from(DatabaseTables.nodes)
            .select(
              'node_id, floor_id, node_code, node_type, label, '
              'description, is_active',
            )
            .inFilter('node_id', destinationNodeIds);

        for (final row in nodeRows) {
          final node = NodeModel.fromJson(Map<String, dynamic>.from(row));
          nodesById[node.nodeId] = node;
        }
      }

      final entries = visits
          .map(
            (visit) => _VisitHistoryEntry(
              visit: visit,
              node: nodesById[visit.destinationNodeId?.trim()],
            ),
          )
          .toList(growable: false);

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } on PostgrestException catch (error) {
      debugPrint('CampusGO visit history query failed: ${error.message}');

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your visit history. Please try again.';
      });
    } catch (error, stackTrace) {
      debugPrint('CampusGO visit history failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage = 'Unable to load your visit history. Please try again.';
      });
    }
  }

  void _closeDrawerThen(VoidCallback action) {
    Navigator.of(context).pop();
    action();
  }

  Future<void> _handleSessionAction() async {
    try {
      await _client.auth.signOut();

      if (!mounted) {
        return;
      }

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to log out. Please try again.')),
      );
    }
  }

  Widget _buildDrawer() {
    return CampusNavigationDrawer(
      isRegisteredUser: true,
      profile: null,
      isAccessibilityEnabled: _isAccessibilityEnabled,
      onProfilePressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.editProfile);
        });
      },
      onNotificationPressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.notifications);
        });
      },
      onTimetablePressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.timetable);
        });
      },
      onSettingsPressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.settings);
        });
      },
      onAccessibilityChanged: (value) {
        setState(() {
          _isAccessibilityEnabled = value;
        });
      },
      onHelpPressed: () {
        _closeDrawerThen(() {
          Navigator.of(context).pushNamed(AppRoutes.support);
        });
      },
      onSessionAction: _handleSessionAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      drawerScrimColor: const Color(0x3D000000),
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _visitHistoryBanner(),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 156,
              bottom: 0,
              child: _buildHistorySheet(),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 70,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        tooltip: 'Open menu',
        splashRadius: 22,
        onPressed: () {
          _scaffoldKey.currentState?.openDrawer();
        },
        icon: SvgPicture.asset(AppAssets.hamburger, width: 27),
      ),
      title: const FittedBox(
        fit: BoxFit.scaleDown,
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
            children: [
              TextSpan(
                text: 'Campus',
                style: TextStyle(color: Color(0xFF38358E)),
              ),
              TextSpan(
                text: 'GO',
                style: TextStyle(color: Color(0xFFFF0000)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Close',
          splashRadius: 22,
          onPressed: () {
            Navigator.of(context).maybePop();
          },
          icon: SvgPicture.asset(AppAssets.closeButton, width: 23),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _visitHistoryBanner() {
    return SizedBox(
      height: 215,
      width: double.infinity,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: -40,
              right: 0,
              top: -18,
              height: 630,
              child: Image.asset(
                AppAssets.loginBackground,
                fit: BoxFit.cover,
                alignment: const Alignment(-0.70, -0.42),
              ),
            ),
            ColoredBox(color: Colors.white.withValues(alpha: 0.10)),
            Positioned(
              left: 108,
              right: 2,
              top: 10,
              bottom: 57,
              child: IgnorePointer(
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(
                    sigmaX: 28.45,
                    sigmaY: 28.45,
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(57),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xEBE8EFFF),
                          Color(0xEBFFFFFF),
                          Color(0xEBE8EFFF),
                        ],
                        stops: [0, 0.53, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 123,
              right: 12,
              top: 8,
              bottom: 57,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 35,
                          fontWeight: FontWeight.w700,
                          height: 1.04,
                        ),
                        children: [
                          TextSpan(
                            text: 'Visit ',
                            style: TextStyle(color: _headingBlue),
                          ),
                          TextSpan(
                            text: 'History',
                            style: TextStyle(color: _headingOrange),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Review the places you have visited and '
                    'quickly navigate there again.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'RobotoCondensed',
                      fontFamilyFallback: ['Roboto'],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _bannerInk,
                      height: 1.10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySheet() {
    const sheetRadius = BorderRadius.vertical(top: Radius.circular(42));

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: sheetRadius,
        boxShadow: [
          BoxShadow(
            color: Color(0x240C3450),
            blurRadius: 18,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: sheetRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.white),
            Opacity(
              opacity: 0.07,
              child: Image.asset(
                AppAssets.loginBackground,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xDFFFFFFF), Color(0xF5FFFFFF)],
                ),
              ),
            ),
            RefreshIndicator(
              color: _headingBlue,
              onRefresh: _loadVisitHistory,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(13, 25, 13, 28),
                children: [
                  const Text(
                    'Recently Visited',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Raleway',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: _sectionHeadingBlue,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_isLoading && _entries.isEmpty)
                    _buildLoadingState()
                  else if (_errorMessage != null && _entries.isEmpty)
                    _buildErrorState()
                  else if (_entries.isEmpty)
                    _buildEmptyState()
                  else
                    ..._entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: _VisitHistoryCard(
                          key: ValueKey(entry.visit.visitId),
                          entry: entry,
                          onNavigate: () {
                            _handleNavigate(entry);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 72),
      child: Center(
        child: CircularProgressIndicator(color: _headingBlue),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 56, horizontal: 24),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 48,
            color: Color(0xFF9AA3AA),
          ),
          SizedBox(height: 12),
          Text(
            'You have not visited any locations yet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Raleway',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF61727D),
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Your previous campus destinations will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'RobotoCondensed',
              fontFamilyFallback: ['Roboto'],
              fontSize: 14,
              color: Color(0xFF7A8289),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 46,
            color: Color(0xFF9AA3AA),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Unable to load your visit history.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'RobotoCondensed',
              fontFamilyFallback: ['Roboto'],
              fontSize: 15,
              color: Color(0xFF61727D),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _loadVisitHistory,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  void _handleNavigate(_VisitHistoryEntry entry) {
    final nodeId = entry.visit.destinationNodeId?.trim();

    if (nodeId == null || nodeId.isEmpty || entry.node?.isActive == false) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Navigation is not available for this location.'),
          ),
        );

      return;
    }

    Navigator.of(context).pushNamed(AppRoutes.userHome, arguments: nodeId);
  }
}

class _VisitHistoryEntry {
  const _VisitHistoryEntry({required this.visit, required this.node});

  final VisitHistoryModel visit;
  final NodeModel? node;

  String get destinationName {
    return node?.displayName ??
        _firstUsefulText([visit.destinationNodeId, 'Campus location']);
  }

  String get description {
    final nodeDescription = node?.description?.trim() ?? '';
    final destination = destinationName.trim();

    if (nodeDescription.isNotEmpty &&
        nodeDescription.toLowerCase() != destination.toLowerCase()) {
      return nodeDescription;
    }

    final nodeType = node?.nodeType?.trim().toLowerCase() ?? '';

    return switch (nodeType) {
      'classroom' => 'Campus classroom',
      'office' => 'Campus office',
      'facility' || 'facilities' => 'Campus facility',
      'washroom' => 'Campus washroom',
      'surau' => 'Campus prayer room',
      _ => 'Previously visited location',
    };
  }

  String get floorLabel {
    final source = _firstUsefulText([
      node?.floorId,
      visit.destinationNodeId?.split('_').first,
    ]);

    if (source.isEmpty) {
      return 'Menara BAC';
    }

    final normalized = source.toUpperCase();

    if (normalized == 'G' || normalized.contains('GROUND')) {
      return 'Ground Floor';
    }

    final number = RegExp(r'\d+').firstMatch(normalized)?.group(0);

    return number == null ? source : 'Level $number';
  }

  String get visitedDateLabel {
    final visitedAt = visit.visitedAt;

    if (visitedAt == null) {
      return '';
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final localDate = visitedAt.toLocal();

    return '${localDate.day} ${months[localDate.month - 1]} ${localDate.year}';
  }

  String get illustrationAsset {
    final nodeType = node?.nodeType?.trim().toLowerCase() ?? '';
    final searchableDescription = [
      node?.nodeType,
      node?.label,
      node?.description,
      node?.tags,
    ].whereType<String>().join(' ').toLowerCase();

    if (searchableDescription.contains('surau') ||
        searchableDescription.contains('prayer') ||
        searchableDescription.contains('pray')) {
      return AppAssets.destinationSurau;
    }

    if (nodeType == 'washroom' ||
        searchableDescription.contains('washroom') ||
        searchableDescription.contains('toilet') ||
        searchableDescription.contains('restroom')) {
      return AppAssets.destinationWashroom;
    }

    if (nodeType == 'office') {
      return AppAssets.destinationOffice;
    }

    if (nodeType == 'classroom' || node == null) {
      return AppAssets.destinationClassroom;
    }

    return AppAssets.destinationFacilities;
  }

  static String _firstUsefulText(List<String?> values) {
    for (final value in values) {
      final text = value?.trim();

      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }
}

class _VisitHistoryCard extends StatelessWidget {
  const _VisitHistoryCard({
    super.key,
    required this.entry,
    required this.onNavigate,
  });

  final _VisitHistoryEntry entry;
  final VoidCallback onNavigate;

  static const Color _blue = Color(0xFF2A77B4);

  @override
  Widget build(BuildContext context) {
    final visitedDate = entry.visitedDateLabel;
    final locationDetails = visitedDate.isEmpty
        ? entry.floorLabel
        : '${entry.floorLabel} · Visited $visitedDate';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 11, 8, 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: Image.asset(
              entry.illustrationAsset,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.destinationName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'RobotoCondensed',
                    fontFamilyFallback: ['Roboto'],
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: _blue,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF61727D),
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 13,
                      color: Color(0xFF959BA2),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationDetails,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'RobotoCondensed',
                          fontFamilyFallback: ['Roboto'],
                          fontSize: 11,
                          color: Color(0xFF959BA2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 156),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: onNavigate,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 27,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _blue),
                        ),
                        alignment: Alignment.center,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Navigate Now',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Raleway',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: _blue,
                                  height: 1,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 15,
                              color: _blue,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
