import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Color(0xFF8A2BE2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Change Password', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField('Current Password', _currentPassController, theme),
              SizedBox(height: 16.h),
              _buildField('New Password', _newPassController, theme),
              SizedBox(height: 16.h),
              _buildField('Confirm New Password', _confirmPassController, theme),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: userProvider.isLoading ? null : () async {
                  if (_newPassController.text.isEmpty || _confirmPassController.text.isEmpty || _currentPassController.text.isEmpty) {
                    _showSnackbar('Fields cannot be empty', isError: true);
                    return;
                  }
                  final errorMessage = await userProvider.changePassword(
                    _currentPassController.text, 
                    _newPassController.text, 
                    _confirmPassController.text,
                  );
                  if (errorMessage == null) {
                    if (mounted) {
                      _showSnackbar('Password changed successfully!');
                      Navigator.pop(context);
                    }
                  } else {
                    _showSnackbar(errorMessage, isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: userProvider.isLoading 
                    ? SizedBox(height: 24.h, width: 24.w, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.w))
                    : Text('Update Password', style: GoogleFonts.inter(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, ThemeData theme) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: GoogleFonts.inter(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.cardColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
      ),
    );
  }
}
