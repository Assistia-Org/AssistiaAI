import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/custom_text_field.dart';
import '../../providers/auth_provider.dart';

class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _oldPasswordController.addListener(_checkForChanges);
    _newPasswordController.addListener(_checkForChanges);
    _confirmPasswordController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasText = _oldPasswordController.text.isNotEmpty ||
        _newPasswordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty;

    if (_hasChanges != hasText) {
      setState(() {
        _hasChanges = hasText;
      });
    }
  }

  @override
  void dispose() {
    _oldPasswordController.removeListener(_checkForChanges);
    _newPasswordController.removeListener(_checkForChanges);
    _confirmPasswordController.removeListener(_checkForChanges);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider).changePassword(
        _oldPasswordController.text,
        _newPasswordController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Şifre başarıyla güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şifre değiştirilemedi: ${e.toString().replaceAll('Exception: Failed to change password: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Şifre Değiştir',
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
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: Form(
                      key: _formKey,
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
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 52,
                                color: Color(0xFF1B232A),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Center(
                            child: Text(
                              'Güvenli bir şifre belirleyin',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          _buildSectionTitle('Mevcut Şifre'),
                          const SizedBox(height: 14),

                          CustomTextField(
                            hintText: 'Eski Şifre',
                            prefixIcon: Icons.lock_outline_rounded,
                            isPassword: true,
                            controller: _oldPasswordController,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Eski şifre boş bırakılamaz';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 30),
                          _buildSectionTitle('Yeni Şifre'),
                          const SizedBox(height: 14),

                          CustomTextField(
                            hintText: 'Yeni Şifre',
                            prefixIcon: Icons.lock_reset_rounded,
                            isPassword: true,
                            controller: _newPasswordController,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Yeni şifre boş bırakılamaz';
                              }
                              if (val.length < 6) {
                                return 'Şifre en az 6 karakter olmalıdır';
                              }
                              if (val == _oldPasswordController.text) {
                                return 'Yeni şifre eski şifreyle aynı olamaz';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 15),

                          CustomTextField(
                            hintText: 'Yeni Şifre (Tekrar)',
                            prefixIcon: Icons.lock_reset_rounded,
                            isPassword: true,
                            controller: _confirmPasswordController,
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Şifre tekrarı boş bırakılamaz';
                              }
                              if (val != _newPasswordController.text) {
                                return 'Şifreler eşleşmiyor';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 40),

                          // Butonlar
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    side: BorderSide(color: Colors.grey[300]!),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    'İptal',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: (!_hasChanges || _isLoading) ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B232A),
                                    disabledBackgroundColor: Colors.grey[200],
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    elevation: 0,
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
                                          'Kaydet',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 50),
                        ],
                      ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
