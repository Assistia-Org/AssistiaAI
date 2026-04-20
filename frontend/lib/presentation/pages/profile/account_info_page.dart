import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_text_field.dart';

class AccountInfoPage extends ConsumerStatefulWidget {
  const AccountInfoPage({super.key});

  @override
  ConsumerState<AccountInfoPage> createState() => _AccountInfoPageState();
}

class _AccountInfoPageState extends ConsumerState<AccountInfoPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _usernameController = TextEditingController(text: user?.username ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');

    _nameController.addListener(_checkForChanges);
    _usernameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final user = ref.read(currentUserProvider);
    final changed = _nameController.text != (user?.displayName ?? '') ||
        _usernameController.text != (user?.username ?? '') ||
        _emailController.text != (user?.email ?? '');

    if (changed != _hasChanges) {
      setState(() {
        _hasChanges = changed;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _usernameController.removeListener(_checkForChanges);
    _emailController.removeListener(_checkForChanges);
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Koyu Arka Plan (Üst Kısım)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(color: const Color(0xFF1B232A)),
          ),
          
          // İçerik
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Üst Header
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Hesap Bilgileri',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                pinned: true,
                expandedHeight: 120,
              ),

              // Form İçeriği
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
                          const SizedBox(height: 30),
                          
                          // Profil Avatar Düzenleme
                          Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 20,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage: NetworkImage(
                                      user?.avatarUrl ?? 'https://i.pravatar.cc/300',
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 3),
                                    ),
                                    child: const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 40),

                          _buildSectionTitle('Kişisel Bilgiler'),
                          const SizedBox(height: 20),
                          
                          CustomTextField(
                            hintText: 'Ad Soyad',
                            prefixIcon: Icons.person_outline_rounded,
                            controller: _nameController,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Ad boş bırakılamaz';
                              if (val.length < 3) return 'Ad en az 3 karakter olmalıdır';
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          
                          CustomTextField(
                            hintText: 'Kullanıcı Adı',
                            prefixIcon: Icons.alternate_email_rounded,
                            controller: _usernameController,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'Kullanıcı adı boş bırakılamaz';
                              if (val.length < 3) return 'Kullanıcı adı en az 3 karakter olmalıdır';
                              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(val)) {
                                return 'Yalnızca harf, rakam ve alt çizgi kullanılabilir';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),
                          
                          CustomTextField(
                            hintText: 'E-posta',
                            prefixIcon: Icons.email_outlined,
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.isEmpty) return 'E-posta boş bırakılamaz';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                                return 'Geçerli bir e-posta girin';
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
                                  onPressed: _hasChanges && !ref.watch(authLoadingProvider)
                                      ? () async {
                                          if (_formKey.currentState!.validate()) {
                                            try {
                                              await ref.read(userControllerProvider).updateProfile(
                                                name: _nameController.text,
                                                username: _usernameController.text,
                                                email: _emailController.text,
                                              );
                                              
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('Bilgiler başarıyla güncellendi'),
                                                    backgroundColor: Colors.green,
                                                  ),
                                                );
                                                // Reset change tracking after successful update
                                                _checkForChanges();
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Hata: $e'),
                                                    backgroundColor: Colors.redAccent,
                                                  ),
                                                );
                                              }
                                            }
                                          }
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1B232A),
                                    disabledBackgroundColor: Colors.grey[200],
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: ref.watch(authLoadingProvider)
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
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[700],
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
