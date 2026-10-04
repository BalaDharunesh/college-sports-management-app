import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/file_downloader.dart';
import '../../../core/utils/date_picker_helper.dart';
import '../providers/staff_provider.dart';

class StaffCreateMatchScreen extends StatefulWidget {
  const StaffCreateMatchScreen({super.key});

  @override
  State<StaffCreateMatchScreen> createState() => _StaffCreateMatchScreenState();
}

class _StaffCreateMatchScreenState extends State<StaffCreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _opponentController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController(text: '09:30:00');
  final _venueController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _descController = TextEditingController();

  // File Upload State
  String? _selectedFileName;
  String? _selectedFileSize;
  String? _fileError;

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

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null && file.bytes!.isNotEmpty) {
          registerUploadedFile(file.name, file.bytes!);
        }
        final sizeInKb = (file.size / 1024).toStringAsFixed(1);
        setState(() {
          _selectedFileName = file.name;
          _selectedFileSize = '$sizeInKb KB';
          _fileError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick file: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFileName = null;
      _selectedFileSize = null;
      _fileError = null;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final matchDateStr = _dateController.text.trim();
    final deadlineStr = _deadlineController.text.trim().isNotEmpty
        ? _deadlineController.text.trim()
        : '$matchDateStr 18:00:00';
    final opponentStr = _opponentController.text.trim().isNotEmpty
        ? _opponentController.text.trim()
        : 'TBD';

    String notesText = _descController.text.trim();
    String fullDescription = '';
    if (_selectedFileName != null) {
      fullDescription = '📄 Attached Fixture Document/Image: $_selectedFileName ($_selectedFileSize)';
      if (notesText.isNotEmpty) {
        fullDescription += '\n\n$notesText';
      }
    } else {
      fullDescription = notesText.isNotEmpty ? notesText : 'Match created by Staff Coordinator';
    }

    final success = await staffProvider.createMatch({
      'title': _titleController.text.trim(),
      'opponentName': opponentStr,
      'matchDate': matchDateStr,
      'startTime': _timeController.text.trim(),
      'venue': _venueController.text.trim(),
      'selectionDeadline': deadlineStr,
      'description': fullDescription,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match created and fixture uploaded successfully!'), backgroundColor: AppColors.success),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Create Match by File / Image Upload')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              CustomTextField(
                controller: _titleController,
                label: 'Match Title *',
                hint: 'e.g. Tournament Fixture Circular Schedule',
                prefixIcon: Icons.sports_cricket_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 14),

              // Date & Time
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _dateController,
                      label: 'Match Date (YYYY-MM-DD) *',
                      hint: 'YYYY-MM-DD',
                      prefixIcon: Icons.calendar_month_outlined,
                      readOnly: true,
                      onTap: () => selectDate(context, _dateController),
                      validator: validateFutureDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _timeController,
                      label: 'Start Time *',
                      hint: '09:30:00',
                      prefixIcon: Icons.access_time_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Time is required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Venue Location
              CustomTextField(
                controller: _venueController,
                label: 'Venue Location *',
                hint: 'e.g. Main University Sports Complex Pitch A',
                prefixIcon: Icons.location_on_outlined,
                validator: (v) => v == null || v.trim().isEmpty ? 'Venue is required' : null,
              ),
              const SizedBox(height: 14),

              // Upload Container (File / Image)
              Text(
                'Upload Fixture File or Image (Optional)',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedFileName == null)
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.cloud_upload_outlined,
                            size: 32,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Click to select file or image',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Supports JPG, PNG, PDF, DOC (Max 10MB)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.success, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _selectedFileName!.endsWith('.pdf')
                              ? Icons.picture_as_pdf_outlined
                              : Icons.image_outlined,
                          color: AppColors.success,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedFileName!,
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedFileSize ?? '',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.change_circle_outlined, color: AppColors.primary),
                        tooltip: 'Change File',
                        onPressed: _pickFile,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        tooltip: 'Remove File',
                        onPressed: _removeFile,
                      ),
                    ],
                  ),
                ),
              if (_fileError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _fileError!,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppColors.error),
                ),
              ],
              const SizedBox(height: 14),

              // Notes / Description
              CustomTextField(
                controller: _descController,
                label: 'Fixture Circular Notes / Special Instructions',
                hint: 'Notes regarding schedule from uploaded circular image/file...',
                prefixIcon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Submit Button
              CustomButton(
                text: 'Publish Uploaded Fixture Match',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.publish_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
