import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.name);
    _emailController = TextEditingController(text: userProvider.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
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
        title: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: theme.appBarTheme.backgroundColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: _emailController,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  filled: true,
                  fillColor: theme.cardColor,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: BorderSide.none),
                ),
              ),
              SizedBox(height: 48.h),
              ElevatedButton(
                onPressed: userProvider.isLoading ? null : () async {
                  final name = _nameController.text.trim();
                  final email = _emailController.text.trim();
                  if (name.isEmpty || email.isEmpty) {
                    _showSnackbar('Fields cannot be empty', isError: true);
                    return;
                  }
                  final success = await userProvider.updateProfile(name, email);
                  if (success) {
                    if (mounted) {
                      _showSnackbar('Profile updated successfully!');
                      Navigator.pop(context);
                    }
                  } else {
                    _showSnackbar('Error updating profile. Please try again.', isError: true);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8A2BE2),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                ),
                child: userProvider.isLoading 
                    ? SizedBox(height: 24.h, width: 24.w, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.w))
                    : Text('Save Changes', style: GoogleFonts.inter(fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
