import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../widgets/custom_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import 'login_page.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> with SingleTickerProviderStateMixin {
  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes
  bool _isTimerActive = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  final int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _codeController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 300;
      _isTimerActive = true;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _isTimerActive = false;
        });
        _timer?.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _resendCode() async {
    try {
      await ref.read(authControllerProvider).requestVerification(_emailController.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Doğrulama kodu yeniden gönderildi!'),
            backgroundColor: Colors.blueAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _codeController.clear();
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kod gönderilemedi: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _nextStep() async {
    if (_formKeys[_currentStep].currentState!.validate()) {
      if (_currentStep == 1) {
        // Step 1: Email -> Request Code
        try {
          await ref.read(authControllerProvider).requestVerification(_emailController.text);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Doğrulama kodu e-postanıza gönderildi!'),
                backgroundColor: Colors.blueAccent,
                behavior: SnackBarBehavior.floating,
              ),
            );
            _startTimer();
            setState(() {
              _currentStep++;
            });
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kod gönderilemedi: ${e.toString()}'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else if (_currentStep == 2) {
        // Step 2: Verification Code -> Verify
        String code = _otpControllers.map((c) => c.text).join();
        if (code.length < 6) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lütfen 6 haneli doğrulama kodunu eksiksiz giriniz.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        if (!_isTimerActive && _secondsRemaining == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kodun süresi doldu. Lütfen yeni bir kod isteyin.'), backgroundColor: Colors.orange),
          );
          return;
        }
        try {
          await ref.read(authControllerProvider).verifyCode(_emailController.text, code);
          setState(() {
            _currentStep++;
          });
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Geçersiz veya süresi dolmuş kod'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else if (_currentStep < _totalSteps - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _register();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _register() async {
    String code = _otpControllers.map((c) => c.text).join();
    try {
      await ref.read(authControllerProvider).register(
        _nameController.text,
        _emailController.text,
        _passwordController.text,
        code,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kayıt Başarılı!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _navigateToLogin();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kayıt Başarısız: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _navigateToLogin() {
    ref.read(authPageProvider.notifier).setPage(AuthPageType.login);
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        bool isCompleted = index < _currentStep;
        bool isActive = index == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: isActive ? 24 : 8,
          decoration: BoxDecoration(
            color: isActive || isCompleted ? Colors.blueAccent : Colors.grey[300],
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildOTPInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 45,
          height: 56,
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            maxLength: 1,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              counterText: "",
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
              ),
              fillColor: Colors.grey[50],
              filled: true,
            ),
            onChanged: (value) {
              if (value.isNotEmpty) {
                if (index < 5) {
                  _otpFocusNodes[index + 1].requestFocus();
                } else {
                  _otpFocusNodes[index].unfocus();
                }
              } else {
                if (index > 0) {
                  _otpFocusNodes[index - 1].requestFocus();
                }
              }
              
              // Update hidden _codeController
              String fullCode = "";
              for (var controller in _otpControllers) {
                fullCode += controller.text;
              }
              _codeController.text = fullCode;
            },
          ),
        );
      }),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return Form(
          key: _formKeys[0],
          child: Column(
            key: const ValueKey(0),
            children: [
              CustomTextField(
                controller: _nameController,
                hintText: 'Ad Soyad',
                prefixIcon: Icons.person_outline,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ad alanı zorunludur' : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Size nasıl hitap etmemizi istersiniz?',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        );
      case 1:
        return Form(
          key: _formKeys[1],
          child: Column(
            key: const ValueKey(1),
            children: [
              CustomTextField(
                controller: _emailController,
                hintText: 'E-posta Adresi',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              Text(
                'Bu adrese bir doğrulama kodu göndereceğiz.',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        );
      case 2:
        return Form(
          key: _formKeys[2],
          child: Column(
            key: const ValueKey(2),
            children: [
              _buildOTPInput(),
              const SizedBox(height: 24),
              if (_isTimerActive)
                Text(
                  'Kodun süresi doluyor: ${_formatTime(_secondsRemaining)}',
                  style: GoogleFonts.inter(
                    color: _secondsRemaining < 30 ? Colors.red : Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                TextButton(
                  onPressed: _resendCode,
                  child: const Text('Kodu Tekrar Gönder'),
                ),
              const SizedBox(height: 16),
              Text(
                'E-postanıza gönderilen kodu girin.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        );
      case 3:
        return Form(
          key: _formKeys[3],
          child: Column(
            key: const ValueKey(3),
            children: [
              CustomTextField(
                controller: _passwordController,
                hintText: 'Şifre',
                prefixIcon: Icons.lock_outline,
                isPassword: true,
                onChanged: (val) => setState(() {}),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: 'Şifreyi Onayla',
                prefixIcon: Icons.lock_reset_outlined,
                isPassword: true,
                onChanged: (val) => setState(() {}),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi onaylayın';
                  }
                  if (value != _passwordController.text) {
                    return 'Şifreler eşleşmiyor';
                  }
                  return null;
                },
              ),
              if (_confirmPasswordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _passwordController.text == _confirmPasswordController.text
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 16,
                      color: _passwordController.text == _confirmPasswordController.text
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _passwordController.text == _confirmPasswordController.text
                          ? 'Şifreler eşleşiyor'
                          : 'Şifreler uyuşmuyor',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _passwordController.text == _confirmPasswordController.text
                            ? Colors.green
                            : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'En az 8 karakterli güçlü bir şifre belirleyin.',
                style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String get _buttonText {
    switch (_currentStep) {
      case 0:
        return 'İleri';
      case 1:
        return 'Kod Al';
      case 2:
        return _isTimerActive ? 'Doğrula' : 'Yeni Kod İste';
      case 3:
        return 'Kayıt Ol';
      default:
        return 'İleri';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0 && _currentStep < 3
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
                onPressed: isLoading ? null : _previousStep,
              )
            : null,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  // Logo or Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blueAccent.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 64,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    'Hesap Oluştur',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Step Indicator
                  _buildStepIndicator(),
                  const SizedBox(height: 32),

                  // Animated Form Content
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _buildCurrentStepContent(),
                  ),
                  
                  const SizedBox(height: 48),

                  // Next / Register Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () {
                        if (_currentStep == 2 && !_isTimerActive) {
                          _resendCode();
                        } else {
                          _nextStep();
                        }
                      },
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
                              _buttonText,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Move to Login
                  if (_currentStep == 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Zaten bir hesabınız var mı?",
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: _navigateToLogin,
                          child: Text(
                            'Giriş Yap',
                            style: GoogleFonts.inter(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
