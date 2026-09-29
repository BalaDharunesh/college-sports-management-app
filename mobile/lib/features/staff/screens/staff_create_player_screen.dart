import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/custom_button.dart';
import '../providers/staff_provider.dart';

class StaffCreatePlayerScreen extends StatefulWidget {
  const StaffCreatePlayerScreen({super.key});

  @override
  State<StaffCreatePlayerScreen> createState() => _StaffCreatePlayerScreenState();
}

class _StaffCreatePlayerScreenState extends State<StaffCreatePlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _regController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _deptController = TextEditingController();
  final _yearController = TextEditingController();
  final _positionController = TextEditingController();
  final _jerseyController = TextEditingController();
  final _passwordController = TextEditingController(text: 'Password123!');

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _regController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _deptController.dispose();
    _yearController.dispose();
    _positionController.dispose();
    _jerseyController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final staffProvider = Provider.of<StaffProvider>(context, listen: false);
    final success = await staffProvider.createPlayer({
      'name': _nameController.text,
      'registerNumber': _regController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'department': _deptController.text,
      'academicYear': _yearController.text,
      'position': _positionController.text,
      'jerseyNumber': _jerseyController.text.isNotEmpty ? int.parse(_jerseyController.text) : null,
      'password': _passwordController.text,
    });

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Player account created successfully!'), backgroundColor: AppColors.success),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create player account. Check duplicate register number or email.'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Player')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomTextField(
                controller: _nameController,
                label: 'Full Name *',
                hint: 'e.g. Virat Kohli',
                prefixIcon: Icons.person_outline,
                validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _regController,
                label: 'Register Number *',
                hint: 'e.g. 22CS045',
                prefixIcon: Icons.badge_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Register Number is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _emailController,
                label: 'College Email *',
                hint: 'player@college.edu',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? 'Email is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _deptController,
                label: 'Department *',
                hint: 'e.g. Computer Science & Engineering',
                prefixIcon: Icons.school_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Department is required' : null,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _yearController,
                label: 'Academic Year *',
                hint: 'e.g. 3rd Year',
                prefixIcon: Icons.calendar_today_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Academic year is required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _positionController,
                      label: 'Playing Position',
                      hint: 'e.g. Batsman / Striker',
                      prefixIcon: Icons.sports_score_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _jerseyController,
                      label: 'Jersey Number',
                      hint: 'e.g. 18',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.numbers_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+19876543210',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _passwordController,
                label: 'Initial Temporary Password',
                hint: 'Password123!',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Register Player Account',
                onPressed: _submit,
                isLoading: _isLoading,
                icon: Icons.check_circle_outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
