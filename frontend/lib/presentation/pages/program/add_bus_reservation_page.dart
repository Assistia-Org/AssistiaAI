import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../domain/entities/reservation/reservation.dart';
import '../../providers/reservation_provider.dart';
import 'package:uuid/uuid.dart';

class AddBusReservationPage extends ConsumerStatefulWidget {
  const AddBusReservationPage({super.key});

  @override
  ConsumerState<AddBusReservationPage> createState() =>
      _AddBusReservationPageState();
}

class _AddBusReservationPageState extends ConsumerState<AddBusReservationPage> {
  Map<String, dynamic>? _extractedData;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      _handleAnalysis(File(image.path), 'image/jpeg');
    }
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      _handleAnalysis(File(result.files.single.path!), 'application/pdf');
    }
  }

  Future<void> _handleAnalysis(File file, String mimeType) async {
    setState(() {
      _extractedData = null;
    });

    try {
      final result = await ref
          .read(reservationControllerProvider)
          .analyzeBusTicket(file, mimeType);

      if (mounted) {
        if (result.containsKey('error')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'].toString()),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
          return;
        }

        setState(() {
          _extractedData = result;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bilet detayları başarıyla çözümlendi!"),
            backgroundColor: Color(0xFFF59E0B),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata oluştu: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B232A),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ref.watch(reservationLoadingProvider)
                        ? _buildAnalyzingState()
                        : _extractedData != null
                        ? _buildResultState()
                        : _buildInitialState(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            "Otobüs Yolculuğu Ekle",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildUploadButton(
          title: "PDF Bileti Yükle",
          subtitle: "E-bilet dosyanızı (PDF) seçin",
          icon: Icons.picture_as_pdf_rounded,
          color: const Color(0xFFF59E0B),
          onTap: _pickFile,
        ),
        const SizedBox(height: 20),
        _buildUploadButton(
          title: "Ekran Görüntüsü Yükle",
          subtitle: "Bilet görselini galeriden seçin",
          icon: Icons.add_photo_alternate_rounded,
          color: const Color(0xFFD97706),
          onTap: _pickImage,
        ),
        const SizedBox(height: 40),
        Text(
          "Yapay zeka bilet üzerindeki bilgileri otomatik olarak okuyup sisteme işleyecektir.",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.white38,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyzingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              color: Color(0xFFF59E0B),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "Analiz Ediliyor...",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Yapay zeka bilet detaylarını çözümlüyor,\nlütfen bekleyin.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white60,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultState() {
    final data = _extractedData!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildResultHeader(),
          const SizedBox(height: 24),

          _buildInfoCard(
            title: "Sefer Bilgileri",
            icon: Icons.directions_bus_rounded,
            color: const Color(0xFFF59E0B),
            content: [
              _buildRow(
                "Nerden/Nereye",
                "${data['departure'] ?? '-'} → ${data['arrival'] ?? '-'}",
              ),
              _buildRow("Otobüs Firması", data['bus_company'] ?? '-'),
              if (data['trip_no'] != null && data['trip_no']!.isNotEmpty)
                _buildRow("Sefer No", data['trip_no']),
              _buildRow("Tarih", data['date'] ?? '-'),
              _buildRow("Kalkış Saati", data['departure_time'] ?? '-'),
              if (data['arrival_time'] != null &&
                  data['arrival_time']!.isNotEmpty)
                _buildRow("Varış Saati", data['arrival_time']),
            ],
          ),
          const SizedBox(height: 16),

          _buildInfoCard(
            title: "Bilet Detayları",
            icon: Icons.confirmation_number_rounded,
            color: const Color(0xFFD97706),
            content: [
              _buildRow("PNR/Bilet No", data['pnr'] ?? '-'),
              _buildRow("Koltuk No", data['seat_number'] ?? '-'),
              _buildRow("Durum", data['status'] ?? '-'),
              _buildRow("Yolcu", data['passenger'] ?? '-'),
            ],
          ),

          const SizedBox(height: 32),
          _buildActionButtons(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildResultHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            color: Colors.greenAccent,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Çözümleme Başarılı",
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "Tüm bilgiler JSON formatına dönüştürüldü.",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUploadButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...content,
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isSaving = ref.watch(reservationLoadingProvider);

    return Row(
      children: [
        Expanded(
          child: _buildSecondaryButton(
            "Yeniden Tara",
            onTap: isSaving
                ? () {}
                : () => setState(() => _extractedData = null),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildPrimaryButton(
            isSaving ? "Kaydediliyor..." : "Onayla ve Kaydet",
            onTap: isSaving
                ? () {}
                : () async {
                    try {
                      const uuid = Uuid();
                      final data = _extractedData!;

                      final reservation = Reservation(
                        id: uuid.v4(),
                        category: "bus",
                        title:
                            "Otobüs: ${data['departure'] ?? '-'} → ${data['arrival'] ?? '-'}",
                        details: data,
                        status: "confirmed",
                      );

                      await ref
                          .read(reservationControllerProvider)
                          .addReservation(reservation);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Otobüs rezervasyonu başarıyla kaydedildi!",
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Kaydedilemedi: ${e.toString()}"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String label, {required VoidCallback onTap}) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white70,
          ),
        ),
      ),
    );
  }
}
