import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

enum EmailChangeStep {
  enterNewEmail,
  verifyNewEmailCode,
  success,
}

class ChangeEmailPage extends ConsumerStatefulWidget {
  const ChangeEmailPage({super.key});

  @override
  ConsumerState<ChangeEmailPage> createState() => _ChangeEmailPageState();
}

class _ChangeEmailPageState extends ConsumerState<ChangeEmailPage> {
  EmailChangeStep _currentStep = EmailChangeStep.enterNewEmail;
  
  final _newEmailController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (index) => FocusNode());
  
  bool _isLoading = false;
  String _currentEmail = '';

  Timer? _timer;
  int _secondsRemaining = 300; // 5 minutes
  bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProcess();
    });
  }

  Future<void> _initProcess() async {
    final user = ref.read(currentUserProvider);
    if (user != null && user.email.isNotEmpty) {
      setState(() {
        _currentEmail = user.email;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mevcut e-posta adresi bulunamadı.'),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _requestVerificationCode(String email) async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).requestVerification(email);
      if (mounted) {
        _startTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$email adresine doğrulama kodu gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kod gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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

  Future<void> _submitNewEmail() async {
    final newEmail = _newEmailController.text.trim();
    if (newEmail.isEmpty || !newEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir e-posta girin'), backgroundColor: Colors.red),
      );
      return;
    }
    
    if (newEmail == _currentEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni e-posta eskisinden farklı olmalıdır'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authControllerProvider).requestVerification(newEmail);
      if (mounted) {
        _startTimer();
        setState(() {
          _currentStep = EmailChangeStep.verifyNewEmailCode;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$newEmail adresine doğrulama kodu gönderildi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _verifyNewEmailAndChange() async {
    final newEmail = _newEmailController.text.trim();
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yanlış veya eksik doğrulama kodu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_isTimerActive && _secondsRemaining == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kodun süresi doldu. Lütfen yeni bir kod isteyin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Önce yeni emaile gelen kodu doğrula
      await ref.read(authControllerProvider).verifyCode(newEmail, code);
      
      // Kod doğruysa kullanıcı profilinde email'i güncelle
      await ref.read(userControllerProvider).updateProfile(email: newEmail);
      
      if (mounted) {
        for (var c in _otpControllers) {
          c.clear();
        }
        setState(() {
          _currentStep = EmailChangeStep.success;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yanlış veya eksik doğrulama kodu.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _newEmailController.dispose();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
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
                borderSide: const BorderSide(color: const Color(0xFF1B232A), width: 2),
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
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Koyu arka plan — üst kısım
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(color: const Color(0xFF1B232A)),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'E-posta Değiştir',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                pinned: true,
                expandedHeight: 120,
              ),

              // Form içeriği
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    height: MediaQuery.of(context).size.height - 180,
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 35),

                        // İkon
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B232A).withValues(alpha: 0.06),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _currentStep == EmailChangeStep.success 
                                ? Icons.check_circle_outline_rounded
                                : Icons.email_outlined,
                              size: 52,
                              color: _currentStep == EmailChangeStep.success 
                                ? Colors.green
                                : const Color(0xFF1B232A),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        Expanded(
                          child: _buildCurrentStepView(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepView() {
    switch (_currentStep) {
      case EmailChangeStep.enterNewEmail:
        return _buildEnterNewEmailView();
      case EmailChangeStep.verifyNewEmailCode:
        return _buildVerifyNewEmailCodeView();
      case EmailChangeStep.success:
        return _buildSuccessView();
    }
  }



  Widget _buildEnterNewEmailView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yeni E-posta Adresi',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Hesabınızla ilişkilendirmek istediğiniz yeni e-posta adresini girin.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        CustomTextField(
          hintText: 'Yeni E-posta Adresi',
          prefixIcon: Icons.email_outlined,
          controller: _newEmailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const Spacer(),
        _buildActionButton('Kod Gönder', _submitNewEmail),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildVerifyNewEmailCodeView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yeni E-posta Doğrulaması',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${_newEmailController.text} adresine gönderdiğimiz 6 haneli doğrulama kodunu girin.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 30),
        _buildOTPInput(),
        const SizedBox(height: 24),
        if (_isTimerActive)
          Center(
            child: Text(
              'Kodun süresi doluyor: ${_formatTime(_secondsRemaining)}',
              style: GoogleFonts.inter(
                color: _secondsRemaining < 30 ? Colors.red : const Color(0xFF1B232A),
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : () => _requestVerificationCode(_newEmailController.text),
              child: Text(
                'Kodu Tekrar Gönder',
                style: GoogleFonts.inter(
                  color: const Color(0xFF1B232A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        const SizedBox(height: 20),
        const Spacer(),
        _buildActionButton('E-postayı Değiştir', _verifyNewEmailAndChange),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Başarılı!',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'E-posta adresiniz başarıyla güncellendi.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.5,
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B232A),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Tamam',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(String text, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B232A),
          disabledBackgroundColor: Colors.grey[200],
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
