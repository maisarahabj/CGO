import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/booking_controller.dart';
import '../models/booking_model.dart';
import '../models/booking_status.dart';
import '../services/booking_service.dart';

/// Matches Figma "18 User book a room 2" exactly: pill-shaped white inputs
/// with #2A77B4 borders and drop shadow, custom segmented Session Type
/// control, gradient Submit button (#2B38A7 -> #FF2B00).
///
/// Self-contained: builds its own locally-scoped BookingController, since
/// this screen can be pushed via Navigator.push (a sibling route), which
/// falls outside BookingsScreen's own provider subtree.
class CreateBookingScreen extends StatelessWidget {
  const CreateBookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    return ChangeNotifierProvider(
      create: (_) => BookingController(BookingService(Supabase.instance.client), userId),
      child: const _CreateBookingScreenBody(),
    );
  }
}

class _CreateBookingScreenBody extends StatefulWidget {
  const _CreateBookingScreenBody();

  @override
  State<_CreateBookingScreenBody> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<_CreateBookingScreenBody> {
  final _formKey = GlobalKey<FormState>();
  final _additionalInfoController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String _sessionType = 'Lecture';
  bool _isSubmitting = false;

  List<Map<String, String>> _rooms = [];
  String? _selectedRoomNodeId;
  bool _isLoadingRooms = true;
  String? _roomsError;

  static const _sessionTypes = ['Lecture', 'Discussion', 'Lab', 'Seminar'];
  static const _borderBlue = Color(0xFF2A77B4);
  static const _labelGrey = Color(0xFF919191);
  static const _valueGrey = Color(0xFF424242);

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoadingRooms = true;
      _roomsError = null;
    });
    try {
      final service = context.read<BookingController>().service;
      final rooms = await service.fetchClassroomRooms();
      setState(() {
        _rooms = rooms;
        _isLoadingRooms = false;
      });
    } catch (e) {
      setState(() => _roomsError = 'Could not load rooms. Please try again.');
    }
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => _endTime = picked);
  }

  Future<void> _submit() async {
    if (_selectedRoomNodeId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a room.')));
      return;
    }
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date, start time, and end time.')));
      return;
    }
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('End time must be after start time.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final controller = context.read<BookingController>();

    final booking = BookingModel(
      bookingId: '',
      userId: '',
      bookDate: _selectedDate!,
      bookStartTime: _formatTime(_startTime!),
      bookEndTime: _formatTime(_endTime!),
      roomNodeId: _selectedRoomNodeId!,
      sessionType: _sessionType,
      additionalInfo: _additionalInfoController.text.trim(),
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );

    final success = await controller.createBooking(booking);
    setState(() => _isSubmitting = false);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request submitted!')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(controller.error ?? 'Something went wrong.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userName = (user?.userMetadata?['full_name'] as String?) ?? '';
    final userEmail = user?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        border: Border.all(color: _borderBlue),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Book a Room',
                                  style: TextStyle(
                                    fontFamily: 'Roboto Flex',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: Color(0xFF606060),
                                  ),
                                ),
                              ),
                              const Icon(Icons.expand_more, color: Color(0xFF868DA6)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Divider(color: _borderBlue, thickness: 1, height: 1),
                          const SizedBox(height: 12),
                          _FieldLabel('Room Name'),
                          const SizedBox(height: 6),
                          _buildRoomDropdown(),
                          const SizedBox(height: 16),
                          _FieldLabel('Your Name'),
                          const SizedBox(height: 6),
                          _PillField(text: userName.isEmpty ? '—' : userName),
                          const SizedBox(height: 16),
                          _FieldLabel('Email'),
                          const SizedBox(height: 6),
                          _PillField(text: userEmail.isEmpty ? '—' : userEmail),
                          const SizedBox(height: 16),
                          _FieldLabel('Date'),
                          const SizedBox(height: 6),
                          _PillButton(
                            text: _selectedDate == null
                                ? 'Select date'
                                : '${_selectedDate!.day.toString().padLeft(2, '0')} - ${_selectedDate!.month.toString().padLeft(2, '0')} - ${_selectedDate!.year.toString().substring(2)}',
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel('Session Type'),
                          const SizedBox(height: 6),
                          _buildSessionTypeControl(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _FieldLabel('Start Time'),
                                    const SizedBox(height: 6),
                                    _PillButton(
                                      text: _startTime?.format(context) ?? 'Select',
                                      onTap: _pickStartTime,
                                      icon: Icons.schedule,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    _FieldLabel('End Time'),
                                    const SizedBox(height: 6),
                                    _PillButton(
                                      text: _endTime?.format(context) ?? 'Select',
                                      onTap: _pickEndTime,
                                      icon: Icons.schedule,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel('Additional Info'),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FF),
                              border: Border.all(color: _borderBlue),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: TextField(
                              controller: _additionalInfoController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Let us know more why you need this room.',
                                hintStyle: TextStyle(
                                  fontFamily: 'Roboto Condensed',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 15,
                                  color: Color(0xFF747474),
                                ),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Roboto Condensed',
                                fontSize: 15,
                                color: _valueGrey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          InkWell(
                            onTap: _isSubmitting ? null : _submit,
                            borderRadius: BorderRadius.circular(52),
                            child: Container(
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [Color(0xFF2B38A7), Color(0xFFFF2B00)],
                                ),
                                borderRadius: BorderRadius.circular(52),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.48),
                                    blurRadius: 7.1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text(
                                      'Submit Booking Request',
                                      style: TextStyle(
                                        fontFamily: 'Raleway',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'An admin will review your request! Please wait patiently for '
                            'approval. You may check under Your Bookings to see if your '
                            'request has been approved.',
                            style: TextStyle(
                              fontFamily: 'Roboto Condensed',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF747474),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF185C92)),
                  onPressed: () => Navigator.maybePop(context),
                ),
              ),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontFamily: 'Raleway', fontWeight: FontWeight.w800, fontSize: 28),
                  children: [
                    TextSpan(text: 'Campus', style: TextStyle(color: Color(0xFF38358E))),
                    TextSpan(text: 'GO', style: TextStyle(color: Color(0xFFE51717))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Book a Room',
            style: TextStyle(
              fontFamily: 'Raleway',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF115388),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 1.2,
            color: _borderBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomDropdown() {
    if (_isLoadingRooms) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }
    if (_roomsError != null) {
      return Row(
        children: [
          Expanded(child: Text(_roomsError!, style: const TextStyle(color: Colors.red))),
          TextButton(onPressed: _loadRooms, child: const Text('Retry')),
        ],
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _borderBlue),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.11), blurRadius: 4, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _selectedRoomNodeId,
          hint: const Text('Select a room', style: TextStyle(fontFamily: 'Roboto Flex', color: _labelGrey)),
          items: _rooms
              .map((room) => DropdownMenuItem(
                    value: room['node_id'],
                    child: Text(
                      room['label'] ?? '',
                      style: const TextStyle(fontFamily: 'Roboto Flex', fontWeight: FontWeight.w500, fontSize: 18, color: _valueGrey),
                    ),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedRoomNodeId = value),
        ),
      ),
    );
  }

  Widget _buildSessionTypeControl() {
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        border: Border.all(color: _borderBlue),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: _sessionTypes.map((type) {
          final selected = _sessionType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _sessionType = type),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: selected
                      ? [BoxShadow(color: Colors.black.withValues(alpha: 0.11), blurRadius: 4, offset: const Offset(0, 4))]
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      type,
                      style: const TextStyle(
                        fontFamily: 'Roboto Flex',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: _valueGrey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _additionalInfoController.dispose();
    super.dispose();
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Roboto Condensed',
        fontWeight: FontWeight.w400,
        fontSize: 15,
        color: Color(0xFF919191),
      ),
    );
  }
}

class _PillField extends StatelessWidget {
  final String text;
  const _PillField({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF2A77B4)),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.11), blurRadius: 4, offset: const Offset(0, 4))],
      ),
      child: Text(
        text,
        style: const TextStyle(fontFamily: 'Roboto Flex', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF424242)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? icon;

  const _PillButton({required this.text, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFF2A77B4)),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.11), blurRadius: 4, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                style: const TextStyle(fontFamily: 'Roboto Flex', fontWeight: FontWeight.w500, fontSize: 16, color: Color(0xFF424242)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (icon != null) Icon(icon, size: 18, color: const Color.fromRGBO(97, 114, 125, 0.55)),
          ],
        ),
      ),
    );
  }
}