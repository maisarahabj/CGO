import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/admin_navigation_controller.dart';
import '../models/node_model.dart';
import '../models/qr_code_model.dart';

/// Admin interface for the existing Supabase qr_codes checkpoint mappings.
///
/// A checkpoint's qr_id identifies the record, while qr_value is the value
/// already encoded in the physical sign. Editing an assignment never changes
/// qr_value, so previously printed CampusGO checkpoints continue to work.
class AdminQrCheckpointsScreen extends StatefulWidget {
  const AdminQrCheckpointsScreen({super.key});

  @override
  State<AdminQrCheckpointsScreen> createState() =>
      _AdminQrCheckpointsScreenState();
}

class _AdminQrCheckpointsScreenState extends State<AdminQrCheckpointsScreen> {
  late final AdminNavigationController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _controller = AdminNavigationController();
    unawaited(_controller.loadCheckpoints());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCheckpointEditor({QrCodeModel? checkpoint}) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => _AdminQrCheckpointEditorScreen(
          controller: _controller,
          checkpoint: checkpoint,
        ),
      ),
    );

    if (!mounted || result == null) return;

    _showMessage(result, isError: false);
  }

  Future<void> _showQrPreview(QrCodeModel checkpoint) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QrPreviewSheet(
        checkpointId: checkpoint.qrId,
        scanValue: _scanValueFor(checkpoint),
        locationName: _controller.locationNameForCheckpoint(checkpoint),
        imageUrl: _controller.imageUrlForCheckpoint(checkpoint),
      ),
    );
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? _CheckpointColors.error
              : _CheckpointColors.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final filteredCheckpoints = _controller.filteredCheckpoints;

            return Column(
              children: [
                _CampusGoPageHeader(
                  title: 'QR Checkpoints',
                  onBackPressed: () => Navigator.of(context).maybePop(),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: _CheckpointSummaryCard(
                    checkpointCount: _controller.checkpoints.length,
                    activeCount: _controller.activeCheckpointCount,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _RoundedSearchField(
                    controller: _searchController,
                    hintText: 'Search checkpoint or location',
                    onChanged: _controller.setSearchQuery,
                    onClear: () {
                      _searchController.clear();
                      _controller.setSearchQuery('');
                    },
                  ),
                ),
                const SizedBox(height: 13),
                SizedBox(
                  height: 43,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _FloorFilterChip(
                        label: 'All',
                        isSelected: _controller.selectedFloor == 'All',
                        onPressed: () => _controller.setSelectedFloor('All'),
                      ),
                      for (final floor
                          in AdminNavigationController.campusFloors)
                        _FloorFilterChip(
                          label: floor,
                          isSelected: _controller.selectedFloor == floor,
                          onPressed: () =>
                              _controller.setSelectedFloor(floor),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 19),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Assigned checkpoints',
                          style: TextStyle(
                            fontFamily: 'Raleway',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _CheckpointColors.deepBlue,
                          ),
                        ),
                      ),
                      Text(
                        '${filteredCheckpoints.length} found',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          color: _CheckpointColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 9),
                Expanded(child: _buildCheckpointList(filteredCheckpoints)),
                _BottomActionBar(
                  label: 'Add checkpoint',
                  icon: Icons.add_rounded,
                  onPressed:
                      _controller.isLoading || _controller.nodes.isEmpty
                      ? null
                      : () => _openCheckpointEditor(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCheckpointList(List<QrCodeModel> checkpoints) {
    if (_controller.isLoading && _controller.checkpoints.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: _CheckpointColors.blue),
      );
    }

    if (_controller.errorMessage != null && _controller.checkpoints.isEmpty) {
      return _CheckpointMessageState(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to load checkpoints',
        message: _controller.errorMessage!,
        actionLabel: 'Try again',
        onAction: _controller.loadCheckpoints,
      );
    }

    return RefreshIndicator(
      color: _CheckpointColors.blue,
      onRefresh: _controller.loadCheckpoints,
      child: checkpoints.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              children: const [
                SizedBox(height: 52),
                _CheckpointMessageState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching checkpoints',
                  message:
                      'Try another search term or select a different floor.',
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 3, 16, 18),
              itemCount: checkpoints.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final checkpoint = checkpoints[index];

                return _CheckpointCard(
                  checkpoint: checkpoint,
                  floor: _controller.floorForCheckpoint(checkpoint),
                  locationName: _controller.locationNameForCheckpoint(
                    checkpoint,
                  ),
                  onManagePressed: () =>
                      _openCheckpointEditor(checkpoint: checkpoint),
                  onViewQrPressed: () => _showQrPreview(checkpoint),
                );
              },
            ),
    );
  }
}

class _AdminQrCheckpointEditorScreen extends StatefulWidget {
  const _AdminQrCheckpointEditorScreen({
    required this.controller,
    this.checkpoint,
  });

  final AdminNavigationController controller;
  final QrCodeModel? checkpoint;

  @override
  State<_AdminQrCheckpointEditorScreen> createState() =>
      _AdminQrCheckpointEditorScreenState();
}

class _AdminQrCheckpointEditorScreenState
    extends State<_AdminQrCheckpointEditorScreen> {
  late final TextEditingController _locationController;
  late final String _checkpointId;
  late final String _scanValue;

  NodeModel? _selectedNode;
  late String _selectedFloor;
  late bool _isActive;
  Uint8List? _selectedImageBytes;
  String? _selectedImageExtension;
  String? _selectedImageName;
  bool _isPickingImage = false;

  bool get _isEditing => widget.checkpoint != null;

  @override
  void initState() {
    super.initState();

    final checkpoint = widget.checkpoint;

    _checkpointId = checkpoint?.qrId ?? widget.controller.nextCheckpointId;
    _scanValue = checkpoint == null
        ? _checkpointId
        : _scanValueFor(checkpoint);
    _selectedNode = checkpoint == null
        ? null
        : widget.controller.nodeForCheckpoint(checkpoint);

    final existingFloor = checkpoint == null
        ? widget.controller.selectedFloor
        : widget.controller.floorForCheckpoint(checkpoint);

    _selectedFloor = AdminNavigationController.campusFloors.contains(
      existingFloor,
    )
        ? existingFloor
        : 'L8';

    _isActive = checkpoint?.isActive ?? true;
    _locationController = TextEditingController(
      text: checkpoint == null
          ? ''
          : widget.controller.locationNameForCheckpoint(checkpoint),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  void _selectFloor(String? floor) {
    if (floor == null || floor == _selectedFloor) return;

    setState(() {
      _selectedFloor = floor;

      final selectedNodeFloor = _selectedNode?.floorId?.toUpperCase() ??
          _selectedNode?.nodeId.split('_').first.toUpperCase();

      if (selectedNodeFloor != floor) _selectedNode = null;
    });
  }

  Future<void> _selectNode() async {
    final selectedNode = await showModalBottomSheet<NodeModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NodePickerSheet(
        floor: _selectedFloor,
        nodes: widget.controller.nodesForFloor(_selectedFloor),
        selectedNodeId: _selectedNode?.nodeId,
      ),
    );

    if (!mounted || selectedNode == null) return;

    setState(() {
      _selectedNode = selectedNode;

      if (_locationController.text.trim().isEmpty) {
        _locationController.text = selectedNode.displayName;
      }
    });
  }

  Future<void> _pickQrImage() async {
    if (_isPickingImage || widget.controller.isSaving) return;

    setState(() => _isPickingImage = true);

    try {
      final selectedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (selectedImage == null || !mounted) return;

      final fileName = selectedImage.name;
      final segments = fileName.split('.');
      final extension = segments.length > 1
          ? segments.last.trim().toLowerCase()
          : '';

      if (!const <String>{'png', 'jpg', 'jpeg', 'webp'}
          .contains(extension)) {
        _showMessage(
          'Choose a PNG, JPG, JPEG, or WEBP QR image.',
          isError: true,
        );
        return;
      }

      final imageBytes = await selectedImage.readAsBytes();

      if (!mounted) return;

      if (imageBytes.isEmpty) {
        _showMessage('The selected QR image is empty.', isError: true);
        return;
      }

      if (imageBytes.lengthInBytes > 5 * 1024 * 1024) {
        _showMessage('Choose a QR image smaller than 5 MB.', isError: true);
        return;
      }

      setState(() {
        _selectedImageBytes = imageBytes;
        _selectedImageExtension = extension;
        _selectedImageName = fileName;
      });
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to open the selected QR image.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _clearSelectedImage() {
    if (widget.controller.isSaving) return;

    setState(() {
      _selectedImageBytes = null;
      _selectedImageExtension = null;
      _selectedImageName = null;
    });
  }

  Future<void> _saveCheckpoint() async {
    if (widget.controller.isSaving) return;

    final selectedNode = _selectedNode;
    final locationName = _locationController.text.trim();

    if (selectedNode == null) {
      _showMessage('Select a navigation node before saving.', isError: true);
      return;
    }

    if (locationName.isEmpty) {
      _showMessage('Enter a checkpoint location name.', isError: true);
      return;
    }

    if (!_isEditing && _selectedImageBytes == null) {
      _showMessage('Upload the generated QR image before saving.', isError: true);
      return;
    }

    FocusScope.of(context).unfocus();

    final success = _isEditing
        ? await widget.controller.updateCheckpoint(
            checkpoint: widget.checkpoint!,
            nodeId: selectedNode.nodeId,
            locationDescription: locationName,
            isActive: _isActive,
            imageBytes: _selectedImageBytes,
            imageExtension: _selectedImageExtension,
          )
        : await widget.controller.createCheckpoint(
            qrId: _checkpointId,
            qrValue: _scanValue,
            nodeId: selectedNode.nodeId,
            locationDescription: locationName,
            isActive: _isActive,
            imageBytes: _selectedImageBytes,
            imageExtension: _selectedImageExtension,
          );

    if (!mounted) return;

    if (!success) {
      _showMessage(
        widget.controller.errorMessage ?? 'Unable to save this checkpoint.',
        isError: true,
      );
      return;
    }

    Navigator.of(context).pop<String>(
      _isEditing
          ? 'Checkpoint $_checkpointId updated successfully.'
          : 'Checkpoint $_checkpointId created successfully.',
    );
  }

  Future<void> _copyScanValue() async {
    await Clipboard.setData(ClipboardData(text: _scanValue));

    if (!mounted) return;

    _showMessage('Checkpoint scan value copied.', isError: false);
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError
              ? _CheckpointColors.error
              : _CheckpointColors.success,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            return Column(
              children: [
                _CampusGoPageHeader(
                  title: _isEditing ? 'Manage Checkpoint' : 'Add Checkpoint',
                  onBackPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(17, 12, 17, 24),
                    children: [
                      _CheckpointPreviewCard(
                        checkpointId: _checkpointId,
                        scanValue: _scanValue,
                        isActive: _isActive,
                        imageBytes: _selectedImageBytes,
                        imageUrl: widget.controller.imageUrlForCheckpoint(
                          widget.checkpoint,
                        ),
                        onActiveChanged: widget.controller.isSaving
                            ? null
                            : (value) {
                                setState(() {
                                  _isActive = value;
                                });
                              },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Checkpoint assignment',
                        style: TextStyle(
                          fontFamily: 'Raleway',
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: _CheckpointColors.deepBlue,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Choose the location that users should receive after '
                        'scanning this checkpoint.',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          height: 1.4,
                          color: _CheckpointColors.mutedText,
                        ),
                      ),
                      const SizedBox(height: 21),
                      _ReadOnlyCheckpointField(
                        label: 'Checkpoint ID',
                        value: _checkpointId,
                      ),
                      const SizedBox(height: 16),
                      _LabeledCheckpointField(
                        label: 'Location name',
                        child: TextField(
                          controller: _locationController,
                          enabled: !widget.controller.isSaving,
                          textCapitalization: TextCapitalization.words,
                          style: _CheckpointTextStyles.field,
                          decoration: _checkpointFieldDecoration(
                            hintText: 'For example, Level 8 Lift Lobby',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledCheckpointField(
                        label: 'Floor',
                        child: _FloorDropdown(
                          selectedFloor: _selectedFloor,
                          enabled: !widget.controller.isSaving,
                          onChanged: _selectFloor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _LabeledCheckpointField(
                        label: 'Assigned node',
                        child: _NodeSelectionField(
                          selectedNode: _selectedNode,
                          enabled: !widget.controller.isSaving,
                          onPressed: _selectNode,
                        ),
                      ),
                      const SizedBox(height: 17),
                      const _CheckpointInformationCard(),
                      const SizedBox(height: 19),
                      _ReadOnlyCheckpointField(
                        label: 'Encoded scan value',
                        value: _scanValue,
                        trailing: IconButton(
                          tooltip: 'Copy scan value',
                          onPressed: _copyScanValue,
                          icon: const Icon(
                            Icons.content_copy_rounded,
                            size: 19,
                            color: _CheckpointColors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 19),
                      _QrImageUploadCard(
                        checkpointId: _checkpointId,
                        scanValue: _scanValue,
                        imageName: _selectedImageName,
                        hasSavedImage:
                            widget.checkpoint?.qrImagePath?.trim().isNotEmpty ==
                                true,
                        hasBundledImage: _qrAssetForId(_checkpointId) != null,
                        isRequired: !_isEditing,
                        isBusy: _isPickingImage || widget.controller.isSaving,
                        onPickImage: _pickQrImage,
                        onClearImage: _selectedImageBytes == null
                            ? null
                            : _clearSelectedImage,
                      ),
                    ],
                  ),
                ),
                _BottomActionBar(
                  label: _isEditing ? 'Save changes' : 'Create checkpoint',
                  isLoading: widget.controller.isSaving,
                  onPressed: widget.controller.isSaving
                      ? null
                      : _saveCheckpoint,
                ),
              ],
            );
          },
        ),
      ),
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
        border: Border(
          bottom: BorderSide(color: Color(0xFFE7EDF0)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBackPressed,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: _CheckpointColors.deepBlue,
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
                        style: TextStyle(color: _CheckpointColors.brandPurple),
                      ),
                      TextSpan(
                        text: 'GO',
                        style: TextStyle(color: _CheckpointColors.brandRed),
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
                    color: _CheckpointColors.deepBlue,
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
              color: _CheckpointColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckpointSummaryCard extends StatelessWidget {
  const _CheckpointSummaryCard({
    required this.checkpointCount,
    required this.activeCount,
  });

  final int checkpointCount;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final inactiveCount = checkpointCount - activeCount;
    final statusMessage = checkpointCount == 0
        ? 'No checkpoints registered yet'
        : inactiveCount == 0
        ? 'All checkpoints active'
        : '$activeCount active · $inactiveCount inactive';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: _checkpointCardDecoration,
      child: Row(
        children: [
          Container(
            width: 51,
            height: 51,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF3FA),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              color: _CheckpointColors.blue,
              size: 29,
            ),
          ),
          const SizedBox(height: 8, width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$checkpointCount '
                  '${checkpointCount == 1 ? 'checkpoint' : 'checkpoints'}',
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _CheckpointColors.darkText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusMessage,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: _CheckpointColors.mutedText,
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

class _RoundedSearchField extends StatelessWidget {
  const _RoundedSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
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
        color: _CheckpointColors.darkText,
      ),
      decoration: _checkpointFieldDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 22,
          color: _CheckpointColors.mutedText,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear search',
                onPressed: onClear,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 19,
                  color: _CheckpointColors.mutedText,
                ),
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
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: isSelected ? _CheckpointColors.blue : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Container(
            constraints: const BoxConstraints(minWidth: 51),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? _CheckpointColors.blue
                    : const Color(0xFFCAD8E0),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : _CheckpointColors.darkText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckpointCard extends StatelessWidget {
  const _CheckpointCard({
    required this.checkpoint,
    required this.floor,
    required this.locationName,
    required this.onManagePressed,
    required this.onViewQrPressed,
  });

  final QrCodeModel checkpoint;
  final String floor;
  final String locationName;
  final VoidCallback onManagePressed;
  final VoidCallback onViewQrPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _checkpointCardDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: onManagePressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 13, 9, 11),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FloorBadge(floor: floor),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locationName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Raleway',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                              color: _CheckpointColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            checkpoint.qrId,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              color: _CheckpointColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            checkpoint.nodeId?.trim().isNotEmpty == true
                                ? 'Node ${checkpoint.nodeId}'
                                : 'No node assigned',
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              color: _CheckpointColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Manage ${checkpoint.qrId}',
                      onPressed: onManagePressed,
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: _CheckpointColors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    const SizedBox(width: 56),
                    _CheckpointStatusLabel(isActive: checkpoint.isActive),
                    const Spacer(),
                    OutlinedButton.icon(
                      onPressed: onViewQrPressed,
                      icon: const Icon(Icons.qr_code_2_rounded, size: 17),
                      label: const Text('View QR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _CheckpointColors.blue,
                        textStyle: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        side: const BorderSide(color: _CheckpointColors.blue),
                        padding: const EdgeInsets.symmetric(horizontal: 11),
                        minimumSize: const Size(0, 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
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

class _FloorBadge extends StatelessWidget {
  const _FloorBadge({required this.floor});

  final String floor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 45,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _floorColor(floor),
        shape: BoxShape.circle,
      ),
      child: Text(
        floor,
        style: const TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CheckpointStatusLabel extends StatelessWidget {
  const _CheckpointStatusLabel({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final statusColor = isActive
        ? _CheckpointColors.success
        : _CheckpointColors.error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ],
    );
  }
}

class _CheckpointPreviewCard extends StatelessWidget {
  const _CheckpointPreviewCard({
    required this.checkpointId,
    required this.scanValue,
    required this.isActive,
    required this.onActiveChanged,
    this.imageBytes,
    this.imageUrl,
  });

  final String checkpointId;
  final String scanValue;
  final bool isActive;
  final ValueChanged<bool>? onActiveChanged;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 12, 10, 9),
      decoration: _checkpointCardDecoration,
      child: Row(
        children: [
          _QrAssetImage(
            checkpointId: checkpointId,
            size: 109,
            imageBytes: imageBytes,
            imageUrl: imageUrl,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkpointId,
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _CheckpointColors.deepBlue,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  scanValue,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    height: 1.35,
                    color: _CheckpointColors.mutedText,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        isActive ? 'Active' : 'Inactive',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _CheckpointColors.darkText,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.84,
                      child: Switch.adaptive(
                        value: isActive,
                        activeColor: _CheckpointColors.blue,
                        onChanged: onActiveChanged,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPreviewSheet extends StatelessWidget {
  const _QrPreviewSheet({
    required this.checkpointId,
    required this.scanValue,
    required this.locationName,
    this.imageUrl,
  });

  final String checkpointId;
  final String scanValue;
  final String locationName;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(23, 11, 23, 25),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD8E1E6),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 19),
            Text(
              checkpointId,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _CheckpointColors.deepBlue,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              locationName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                color: _CheckpointColors.mutedText,
              ),
            ),
            const SizedBox(height: 16),
            _QrAssetImage(
              checkpointId: checkpointId,
              size: 235,
              imageUrl: imageUrl,
            ),
            const SizedBox(height: 13),
            const Text(
              'Encoded scan value',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: _CheckpointColors.mutedText,
              ),
            ),
            const SizedBox(height: 4),
            SelectableText(
              scanValue,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _CheckpointColors.darkText,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: scanValue));

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checkpoint value copied.')),
                  );
                },
                icon: const Icon(Icons.content_copy_rounded, size: 18),
                label: const Text('Copy scan value'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _CheckpointColors.blue,
                  side: const BorderSide(color: _CheckpointColors.blue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrAssetImage extends StatelessWidget {
  const _QrAssetImage({
    required this.checkpointId,
    required this.size,
    this.imageBytes,
    this.imageUrl,
  });

  final String checkpointId;
  final double size;
  final Uint8List? imageBytes;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final assetPath = _qrAssetForId(checkpointId);

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EEF1)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: imageBytes != null
          ? Image.memory(
              imageBytes!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) =>
                  _QrImageUnavailable(checkpointId: checkpointId),
            )
          : imageUrl != null && imageUrl!.trim().isNotEmpty
              ? Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;

                    return const Center(
                      child: CircularProgressIndicator(
                        color: _CheckpointColors.blue,
                        strokeWidth: 2,
                      ),
                    );
                  },
                  errorBuilder: (_, _, _) => assetPath == null
                      ? _QrImageUnavailable(checkpointId: checkpointId)
                      : Image.asset(
                          assetPath,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) =>
                              _QrImageUnavailable(checkpointId: checkpointId),
                        ),
                )
              : assetPath == null
                  ? _QrImageUnavailable(checkpointId: checkpointId)
                  : Image.asset(
                      assetPath,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          _QrImageUnavailable(checkpointId: checkpointId),
                    ),
    );
  }
}

class _QrImageUploadCard extends StatelessWidget {
  const _QrImageUploadCard({
    required this.checkpointId,
    required this.scanValue,
    required this.imageName,
    required this.hasSavedImage,
    required this.hasBundledImage,
    required this.isRequired,
    required this.isBusy,
    required this.onPickImage,
    required this.onClearImage,
  });

  final String checkpointId;
  final String scanValue;
  final String? imageName;
  final bool hasSavedImage;
  final bool hasBundledImage;
  final bool isRequired;
  final bool isBusy;
  final VoidCallback onPickImage;
  final VoidCallback? onClearImage;

  @override
  Widget build(BuildContext context) {
    final hasSelection = imageName != null;
    final description = hasSelection
        ? 'The selected image will be saved when you confirm this checkpoint.'
        : hasSavedImage
            ? 'An uploaded QR image is already saved. You can replace it here.'
            : hasBundledImage
                ? 'This checkpoint already uses its original CampusGO QR '
                    'image. Uploading a replacement is optional.'
                : 'Upload the QR image generated for $checkpointId. Its '
                    'encoded value must exactly match "$scanValue".';

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _checkpointCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.image_outlined,
                size: 21,
                color: _CheckpointColors.blue,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  isRequired ? 'QR image *' : 'QR image',
                  style: const TextStyle(
                    fontFamily: 'Raleway',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _CheckpointColors.deepBlue,
                  ),
                ),
              ),
              if (hasSelection)
                IconButton(
                  tooltip: 'Remove selected image',
                  onPressed: isBusy ? null : onClearImage,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: _CheckpointColors.mutedText,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              height: 1.45,
              color: _CheckpointColors.mutedText,
            ),
          ),
          if (hasSelection) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8FB),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                imageName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _CheckpointColors.deepBlue,
                ),
              ),
            ),
          ],
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : onPickImage,
              icon: Icon(
                hasSelection || hasSavedImage
                    ? Icons.sync_rounded
                    : Icons.upload_file_rounded,
                size: 18,
              ),
              label: Text(
                hasSelection || hasSavedImage
                    ? 'Replace QR image'
                    : 'Upload QR image',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _CheckpointColors.blue,
                side: const BorderSide(color: _CheckpointColors.blue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(23),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Raleway',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'PNG, JPG, JPEG or WEBP, up to 5 MB.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: _CheckpointColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrImageUnavailable extends StatelessWidget {
  const _QrImageUnavailable({required this.checkpointId});

  final String checkpointId;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.qr_code_2_rounded,
            size: 38,
            color: _CheckpointColors.blue,
          ),
          const SizedBox(height: 5),
          FittedBox(
            child: Text(
              checkpointId,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _CheckpointColors.mutedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NodePickerSheet extends StatefulWidget {
  const _NodePickerSheet({
    required this.floor,
    required this.nodes,
    required this.selectedNodeId,
  });

  final String floor;
  final List<NodeModel> nodes;
  final String? selectedNodeId;

  @override
  State<_NodePickerSheet> createState() => _NodePickerSheetState();
}

class _NodePickerSheetState extends State<_NodePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<NodeModel> get _filteredNodes {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return widget.nodes;

    return widget.nodes.where((node) {
      final searchableText = <String>[
        node.displayName,
        node.nodeId,
        node.nodeType ?? '',
        node.description ?? '',
      ].join(' ').toLowerCase();

      return query
          .split(RegExp(r'\s+'))
          .where((term) => term.isNotEmpty)
          .every(searchableText.contains);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final nodes = _filteredNodes;

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        padding: const EdgeInsets.fromLTRB(17, 12, 17, 0),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E1E6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select a ${widget.floor} node',
                      style: const TextStyle(
                        fontFamily: 'Raleway',
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: _CheckpointColors.deepBlue,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close node picker',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 11),
              _RoundedSearchField(
                controller: _searchController,
                hintText: 'Search by location or node ID',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                onClear: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
              const SizedBox(height: 13),
              Expanded(
                child: nodes.isEmpty
                    ? const _CheckpointMessageState(
                        icon: Icons.location_off_outlined,
                        title: 'No matching nodes',
                        message: 'Try another location or node ID.',
                      )
                    : ListView.separated(
                        itemCount: nodes.length,
                        separatorBuilder: (_, _) => const Divider(
                          height: 1,
                          indent: 49,
                          color: Color(0xFFE8EEF1),
                        ),
                        itemBuilder: (context, index) {
                          final node = nodes[index];
                          final isSelected =
                              node.nodeId == widget.selectedNodeId;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            onTap: () => Navigator.of(context).pop(node),
                            leading: CircleAvatar(
                              radius: 19,
                              backgroundColor: const Color(0xFFEAF3FA),
                              child: Icon(
                                isSelected
                                    ? Icons.check_rounded
                                    : Icons.place_outlined,
                                size: 21,
                                color: _CheckpointColors.blue,
                              ),
                            ),
                            title: Text(
                              node.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _CheckpointColors.darkText,
                              ),
                            ),
                            subtitle: Text(
                              node.nodeType?.trim().isNotEmpty == true
                                  ? '${node.nodeId} · ${node.nodeType}'
                                  : node.nodeId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12,
                                color: _CheckpointColors.mutedText,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: _CheckpointColors.blue,
                                  )
                                : const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF9AABB4),
                                  ),
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
}

class _LabeledCheckpointField extends StatelessWidget {
  const _LabeledCheckpointField({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 13, bottom: 7),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _CheckpointColors.mutedText,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _ReadOnlyCheckpointField extends StatelessWidget {
  const _ReadOnlyCheckpointField({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _LabeledCheckpointField(
      label: label,
      child: Container(
        height: 51,
        padding: const EdgeInsets.only(left: 17, right: 5),
        decoration: _roundedFieldDecoration,
        child: Row(
          children: [
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _CheckpointTextStyles.field,
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _FloorDropdown extends StatelessWidget {
  const _FloorDropdown({
    required this.selectedFloor,
    required this.enabled,
    required this.onChanged,
  });

  final String selectedFloor;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 51,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: _roundedFieldDecoration,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedFloor,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: _CheckpointColors.blue,
          ),
          style: _CheckpointTextStyles.field,
          items: AdminNavigationController.campusFloors
              .map(
                (floor) => DropdownMenuItem<String>(
                  value: floor,
                  child: Text(
                    floor == 'G' ? 'Ground Floor · G' : 'Level ${floor.substring(1)} · $floor',
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

class _NodeSelectionField extends StatelessWidget {
  const _NodeSelectionField({
    required this.selectedNode,
    required this.enabled,
    required this.onPressed,
  });

  final NodeModel? selectedNode;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: enabled ? onPressed : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.fromLTRB(15, 10, 11, 10),
          decoration: _roundedFieldDecoration,
          child: Row(
            children: [
              const Icon(
                Icons.place_outlined,
                size: 21,
                color: _CheckpointColors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: selectedNode == null
                    ? const Text(
                        'Select a navigation node',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: _CheckpointColors.mutedText,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedNode!.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _CheckpointColors.darkText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selectedNode!.nodeId,
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: _CheckpointColors.mutedText,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.chevron_right_rounded,
                color: _CheckpointColors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckpointInformationCard extends StatelessWidget {
  const _CheckpointInformationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7FB),
        border: Border.all(color: const Color(0xFFD3E6F4)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: _CheckpointColors.blue,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Changing the assigned node updates the user’s current '
              'location without replacing the physical QR.',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                height: 1.45,
                color: _CheckpointColors.deepBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6EDF0))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 49,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: onPressed == null && !isLoading
                ? const LinearGradient(
                    colors: <Color>[Color(0xFFB7BFC7), Color(0xFFB7BFC7)],
                  )
                : const LinearGradient(
                    colors: <Color>[
                      Color(0xFF3235BD),
                      Color(0xFF7D2C87),
                      Color(0xFFFF2A0A),
                    ],
                  ),
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(34),
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
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 21, color: Colors.white),
                        const SizedBox(width: 7),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
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

class _CheckpointMessageState extends StatelessWidget {
  const _CheckpointMessageState({
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
        padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 43, color: _CheckpointColors.blue),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Raleway',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _CheckpointColors.deepBlue,
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
                color: _CheckpointColors.mutedText,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 13),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _CheckpointColors.blue,
                  side: const BorderSide(color: _CheckpointColors.blue),
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

class _CheckpointColors {
  static const Color blue = Color(0xFF2A77B4);
  static const Color deepBlue = Color(0xFF115388);
  static const Color brandPurple = Color(0xFF38358E);
  static const Color brandRed = Color(0xFFFF0000);
  static const Color darkText = Color(0xFF26333C);
  static const Color mutedText = Color(0xFF76828B);
  static const Color success = Color(0xFF278746);
  static const Color error = Color(0xFFBC373E);
}

class _CheckpointTextStyles {
  static const TextStyle field = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: _CheckpointColors.darkText,
  );
}

BoxDecoration get _checkpointCardDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(21),
  border: Border.all(color: const Color(0xFFE1EAF0)),
  boxShadow: const <BoxShadow>[
    BoxShadow(
      color: Color(0x11000000),
      blurRadius: 11,
      offset: Offset(0, 3),
    ),
  ],
);

BoxDecoration get _roundedFieldDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(27),
  border: Border.all(color: const Color(0xFF7EAED0)),
);

InputDecoration _checkpointFieldDecoration({
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    hintText: hintText,
    hintStyle: const TextStyle(
      fontFamily: 'Roboto',
      fontSize: 13,
      color: Color(0xFF94A0A8),
    ),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 15),
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
      borderSide: const BorderSide(
        color: _CheckpointColors.blue,
        width: 1.4,
      ),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(27),
      borderSide: const BorderSide(color: Color(0xFFD5DDE2)),
    ),
  );
}

String _scanValueFor(QrCodeModel checkpoint) {
  final scanValue = checkpoint.qrValue?.trim();

  return scanValue != null && scanValue.isNotEmpty
      ? scanValue
      : checkpoint.qrId;
}

String? _qrAssetForId(String checkpointId) {
  const qrImages = <String, String>{
    'QR001': 'assets/features/navigation/maps/QR/QR001_G.png',
    'QR002': 'assets/features/navigation/maps/QR/QR002_L1.png',
    'QR003': 'assets/features/navigation/maps/QR/QR003_L3.png',
    'QR004': 'assets/features/navigation/maps/QR/QR004_L6.png',
    'QR005': 'assets/features/navigation/maps/QR/QR005_L8.png',
    'QR006': 'assets/features/navigation/maps/QR/QR006_L9.png',
  };

  return qrImages[checkpointId.trim().toUpperCase()];
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
