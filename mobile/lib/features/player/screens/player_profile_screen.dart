import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class PlayerProfileScreen extends StatelessWidget {
  const PlayerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('My Sports Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppColors.accent,
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'P',
                      style: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.name ?? '', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('${user?.department ?? ""} (${user?.academicYear ?? ""})', style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildRow('College Email', user?.email ?? ''),
                    const Divider(),
                    _buildRow('Register Number', user?.registerNumber ?? 'N/A'),
                    const Divider(),
                    _buildRow('Sport', user?.sportName ?? 'N/A'),
                    const Divider(),
                    _buildRow('Assigned Team', user?.teamName ?? 'N/A'),
                    const Divider(),
                    _buildRow('Playing Position', user?.position ?? 'N/A'),
                    const Divider(),
                    _buildRow('Jersey Number', user?.jerseyNumber != null ? '#${user!.jerseyNumber}' : 'N/A'),
                    const Divider(),
                    _buildRow('Phone', user?.phone ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
