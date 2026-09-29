import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/staff_provider.dart';

class StaffCreateMatchScreen extends StatefulWidget {
  const StaffCreateMatchScreen({super.key});

  @override
  State<StaffCreateMatchScreen> createState() => _StaffCreateMatchScreenState();
}

class _StaffCreateMatchScreenState extends State<StaffCreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _opponentController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController(text: '09:30:00');
  final _venueController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _descController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final nextWeek = today.add(const Duration(days: 7));
    final deadline = today.add(const Duration(days: 5));
    _dateController.text = nextWeek.toIso8601String().split('T')[0];
    _deadlineController.text = '${deadline.toIso8601String().split('T')[0]} 18:00:00';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _opponentController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _venueController.dispose();
    _deadlineController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final success = await staffProvider.createMatch({
      'title': _titleController.text,
      'opponentName': _opponentController.text,
      'matchDate': _dateController.text,
      'startTime': _timeController.text,
      'venue': _venueController.text,
      'selectionDeadline': _deadlineController.text,
      'description': _descController.text,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match created successfully!'), backgroundColor: AppColors.success),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create match.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schedule New Match')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _titleController,
                label: 'Match Title *',
                hint: 'e.g. Inter-College T20 Quarter-Final',
                prefixIcon: Icons.sports_cricket_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _opponentController,
                label: 'Opponent Team Name *',
                hint: 'e.g. Loyola College XI',
                prefixIcon: Icons.shield_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Opponent name is required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _dateController,
                      label: 'Match Date (YYYY-MM-DD) *',
                      hint: 'YYYY-MM-DD',
                      prefixIcon: Icons.calendar_month_outlined,
                      validator: (v) => v == null || v.isEmpty ? 'Date is required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _timeController,
                      label: 'Start Time *',
                      hint: '09:30:00',
                      prefixIcon: Icons.access_time_outlined,
                      validator: (v) => v == null || v.isEmpty ? 'Time is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _venueController,
                label: 'Venue Location *',
                hint: 'e.g. Main University Sports Complex Pitch A',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Venue is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _deadlineController,
                label: 'Selection Deadline (YYYY-MM-DD HH:MM:SS) *',
                hint: 'YYYY-MM-DD 18:00:00',
                prefixIcon: Icons.timer_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Selection deadline is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _descController,
                label: 'Match Description / Notes',
                hint: 'Tournament guidelines, jersey requirements, kit requirements...',
                prefixIcon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Schedule Match',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.event_available_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
