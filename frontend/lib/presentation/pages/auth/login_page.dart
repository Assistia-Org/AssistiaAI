import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import 'register_page.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(authControllerProvider).login(
          _emailController.text,
          _passwordController.text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Login Successful!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login Failed: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _navigateToRegister() {
    // Navigate with a custom SlideTransition
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(text: _emailController.text);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        String? localErrorMessage;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 24,
          top: 16,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blueAccent.withValues(alpha: 0.1),
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                size: 40,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 20),
            
            // Texts
            Text(
              'Şifremi Unuttum',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hesabınıza bağlı e-posta adresini girin.\nSize bir şifre sıfırlama bağlantısı göndereceğiz.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // Text Field
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: 'ornek@email.com',
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            
            // Error Message Display
            if (localErrorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        localErrorMessage!,
                        style: GoogleFonts.inter(
                          color: Colors.red.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      'İptal',
                      style: GoogleFonts.inter(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      setState(() {
                        localErrorMessage = null;
                        isSubmitting = true;
                      });
                      
                      final emailText = resetEmailController.text.trim();
                      if (emailText.isEmpty) {
                        setState(() {
                          localErrorMessage = 'E-posta alanı boş bırakılamaz.';
                          isSubmitting = false;
                        });
                        return;
                      }
                      
                      // Validate email format
                      final errorMsg = Validators.validateEmail(emailText);
                      if (errorMsg != null) {
                        setState(() {
                          localErrorMessage = 'Lütfen geçerli bir email adresi girin.';
                          isSubmitting = false;
                        });
                        return; // Stop execution without closing the bottom sheet
                      }
                      
                      try {
                        // Use the main page's context safely
                        await ref.read(authControllerProvider).forgotPassword(emailText);
                        
                        // Close bottom sheet ONLY after a successful operation
                        if (mounted) {
                          Navigator.pop(dialogContext); // Close bottom sheet
                          
                          ScaffoldMessenger.of(context).showSnackBar( // Context from main page
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Sıfırlama bağlantısı e-postanıza gönderildi.',
                                      style: GoogleFonts.inter(),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green.shade600,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      } catch (e) {
                        final errorString = e.toString().toLowerCase();
                        
                        setState(() {
                          if (errorString.contains('user_not_found') || errorString.contains('user not found')) {
                            localErrorMessage = 'Böyle bir kullanıcı bulunamadı.';
                          } else {
                            localErrorMessage = 'Hata: ${e.toString()}';
                          }
                          isSubmitting = false;
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting 
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Text(
                          'Gönder',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
   );
  },
 );
}

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo or Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent.withValues(alpha: 0.1),
                        ),
                        child: const Icon(
                          Icons.lock_outline_rounded,
                          size: 64,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Title
                      Text(
                        'Welcome Back',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to continue',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email Field
                      CustomTextField(
                        controller: _emailController,
                        hintText: 'Email Address',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      CustomTextField(
                        controller: _passwordController,
                        hintText: 'Password',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 12),

                      // Forgot Password Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            'Şifremi Unuttum?',
                            style: GoogleFonts.inter(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Login Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Move to Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: GoogleFonts.inter(color: Colors.grey[600]),
                          ),
                          TextButton(
                            onPressed: _navigateToRegister,
                            child: Text(
                              'Sign up',
                              style: GoogleFonts.inter(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.bold,
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
          ),
        ),
      ),
    );
  }
}
