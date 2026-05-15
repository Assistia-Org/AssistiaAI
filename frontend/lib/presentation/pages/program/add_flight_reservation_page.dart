import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/reservation/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/daily_program_provider.dart';
import '../../widgets/assignment_selector.dart';
import '../../widgets/location_picker_widget.dart';

class AddFlightReservationPage extends ConsumerStatefulWidget {
  const AddFlightReservationPage({super.key});

  @override
  ConsumerState<AddFlightReservationPage> createState() =>
      _AddFlightReservationPageState();
}

class _AddFlightReservationPageState
    extends ConsumerState<AddFlightReservationPage> {
  // ── Form ─────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _departureCtrl = TextEditingController();
  final _arrivalCtrl = TextEditingController();
  final _flightNoCtrl = TextEditingController();
  final _airlineCtrl = TextEditingController();
  final _pnrCtrl = TextEditingController();
  final _passengerCtrl = TextEditingController();

  DateTime _departureDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _departureTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _arrivalTime = const TimeOfDay(hour: 12, minute: 0);

  // ── AI Section ───────────────────────────────────────────────────────────
  bool _isAiExpanded = false;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();

  // ── Other ────────────────────────────────────────────────────────────────
  bool _isSubmitting = false;
  String? _communityId;
  List<String> _assignedTo = [];
  String? _locationAddress;
  double? _locationLat;
  double? _locationLng;

  static const Color _accent = Color(0xFF0EA5E9);
  static const Color _bg = Color(0xFF1B232A);
  static const Color _card = Color(0xFF263040);

  @override
  void dispose() {
    _departureCtrl.dispose();
    _arrivalCtrl.dispose();
    _flightNoCtrl.dispose();
    _airlineCtrl.dispose();
    _pnrCtrl.dispose();
    _passengerCtrl.dispose();
    super.dispose();
  }

  // ── AI Handlers ──────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final f = await _picker.pickImage(source: ImageSource.gallery);
    if (f != null) _handleAnalysis(File(f.path), 'image/jpeg');
  }

  Future<void> _pickFile() async {
    final r = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (r != null && r.files.single.path != null) {
      _handleAnalysis(File(r.files.single.path!), 'application/pdf');
    }
  }

  Future<void> _handleAnalysis(File file, String mimeType) async {
    setState(() => _isAnalyzing = true);
    try {
      final result = await ref
          .read(reservationControllerProvider)
          .analyzeTicket(file, mimeType);
      if (!mounted) return;
      if (result.containsKey('error')) {
        _showSnack(result['error'].toString(), isError: true);
      } else {
        _fillFromAI(result);
        setState(() => _isAiExpanded = false);
        _showSnack('✅ Form AI tarafından dolduruldu!');
      }
    } catch (e) {
      if (mounted) _showSnack('Hata: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _fillFromAI(Map<String, dynamic> d) {
    _departureCtrl.text = d['departure'] ?? '';
    _arrivalCtrl.text = d['arrival'] ?? '';
    _flightNoCtrl.text = d['flight_no'] ?? '';
    _airlineCtrl.text = d['airline'] ?? '';
    _pnrCtrl.text = d['pnr'] ?? '';
    _passengerCtrl.text = d['passenger'] ?? '';
    if (d['date'] != null) {
      try {
        setState(() =>
            _departureDate = DateFormat('yyyy-MM-dd').parse(d['date']));
      } catch (_) {}
    }
    _parseTime(d['departure_time'],
        (t) => setState(() => _departureTime = t));
    _parseTime(d['arrival_time'],
        (t) => setState(() => _arrivalTime = t));
    setState(() {});
  }

  void _parseTime(dynamic raw, void Function(TimeOfDay) cb) {
    if (raw == null) return;
    try {
      final p = (raw as String).split(':');
      cb(TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1])));
    } catch (_) {}
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final dep = DateTime(_departureDate.year, _departureDate.month,
        _departureDate.day, _departureTime.hour, _departureTime.minute);
    final arr = DateTime(_departureDate.year, _departureDate.month,
        _departureDate.day, _arrivalTime.hour, _arrivalTime.minute);

    final details = {
      'departure': _departureCtrl.text,
      'arrival': _arrivalCtrl.text,
      'flight_no': _flightNoCtrl.text,
      'airline': _airlineCtrl.text,
      'pnr': _pnrCtrl.text,
      'passenger': _passengerCtrl.text,
      'date': DateFormat('yyyy-MM-dd').format(_departureDate),
      'departure_time': _fmtTime(_departureTime),
      'arrival_time': _fmtTime(_arrivalTime),
    };

    final reservation = Reservation(
      category: 'flight',
      title: 'Uçuş: ${_departureCtrl.text} → ${_arrivalCtrl.text}',
      details: details,
      startDate: dep,
      endDate: arr,
      communityId: _communityId,
      assignedTo: _assignedTo,
      status: 'confirmed',
      locationAddress: _locationAddress,
      locationLat: _locationLat,
      locationLng: _locationLng,
    );

    try {
      await ref.read(reservationControllerProvider).addReservation(reservation);
      ref.invalidate(
          dailyProgramByDateProvider(DateFormat('yyyy-MM-dd').format(DateTime.now())));
      if (mounted) {
        Navigator.pop(context);
        _showSnack('Uçuş rezervasyonu eklendi!');
      }
    } catch (e) {
      if (mounted) _showSnack('Kayıt hatası: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inter()),
      backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildAiSection(),
                    const SizedBox(height: 24),
                    _sectionLabel('UÇUŞ BİLGİLERİ', Icons.airplanemode_active_rounded, _accent),
                    const SizedBox(height: 12),
                    _row2(
                      _textField(_departureCtrl, 'Kalkış', 'IST, Ankara...', Icons.flight_takeoff_rounded, required: true),
                      _textField(_arrivalCtrl, 'Varış', 'AYT, İzmir...', Icons.flight_land_rounded, required: true),
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      _textField(_airlineCtrl, 'Havayolu', 'THY, Pegasus...', Icons.airlines_rounded),
                      _textField(_flightNoCtrl, 'Uçuş No', 'TK1234', Icons.numbers_rounded),
                    ),
                    const SizedBox(height: 12),
                    _dateTile(),
                    const SizedBox(height: 12),
                    _row2(
                      _timeTile('Kalkış', _departureTime, (t) => setState(() => _departureTime = t)),
                      _timeTile('Varış', _arrivalTime, (t) => setState(() => _arrivalTime = t)),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('REZERVASYON DETAYI', Icons.confirmation_number_rounded, const Color(0xFF8B5CF6)),
                    const SizedBox(height: 12),
                    _row2(
                      _textField(_pnrCtrl, 'PNR No', 'ABC123', Icons.qr_code_rounded),
                      _textField(_passengerCtrl, 'Yolcu Adı', 'Ad Soyad', Icons.person_rounded),
                    ),
                    const SizedBox(height: 24),
                    _sectionLabel('ATAMA & KONUM', Icons.group_rounded, const Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    AssignmentSelector(
                      onChanged: (c, a) => setState(() { _communityId = c; _assignedTo = a; }),
                    ),
                    const SizedBox(height: 12),
                    LocationPickerWidget(
                      accentColor: _accent,
                      onChanged: (r) => setState(() {
                        _locationAddress = r?.address;
                        _locationLat = r?.lat;
                        _locationLng = r?.lng;
                      }),
                    ),
                    const SizedBox(height: 32),
                    _submitBtn(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          Text('Uçuş Rezervasyonu',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        ]),
      );

  Widget _buildAiSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_accent.withValues(alpha: 0.12), const Color(0xFF8B5CF6).withValues(alpha: 0.08)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _isAiExpanded = !_isAiExpanded),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: _accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI ile Otomatik Doldur',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                Text('PDF veya fotoğraftan bilet bilgilerini otomatik al',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
              ])),
              Icon(_isAiExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                  color: Colors.white38),
            ]),
          ),
        ),
        if (_isAiExpanded) ...[
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.08)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _isAnalyzing
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Column(children: [
                      CircularProgressIndicator(color: _accent, strokeWidth: 3),
                      SizedBox(height: 12),
                      Text('Bilet analiz ediliyor...',
                          style: TextStyle(color: Colors.white60, fontSize: 13)),
                    ]))
                : Row(children: [
                    Expanded(child: _aiBtn('PDF Yükle', Icons.picture_as_pdf_rounded, _accent, _pickFile)),
                    const SizedBox(width: 12),
                    Expanded(child: _aiBtn('Fotoğraf', Icons.add_photo_alternate_rounded, const Color(0xFF8B5CF6), _pickImage)),
                  ]),
          ),
        ],
      ]),
    );
  }

  Widget _aiBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
          ]),
        ),
      );

  Widget _sectionLabel(String title, IconData icon, Color color) => Row(children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(title,
            style: GoogleFonts.inter(
                color: color, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
      ]);

  Widget _row2(Widget a, Widget b) =>
      Row(children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)]);

  Widget _textField(TextEditingController ctrl, String label, String hint, IconData icon,
      {bool required = false}) {
    return TextFormField(
      controller: ctrl,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Zorunlu' : null : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: _accent, size: 18),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _accent)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.redAccent)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  Widget _dateTile() => _tappable(
        onTap: () async {
          final p = await showDatePicker(
            context: context,
            initialDate: _departureDate,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
          );
          if (p != null) setState(() => _departureDate = p);
        },
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, color: _accent, size: 18),
          const SizedBox(width: 10),
          Text('Uçuş Tarihi', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13)),
          const Spacer(),
          Text(DateFormat('dd/MM/yyyy').format(_departureDate),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _timeTile(String label, TimeOfDay t, ValueChanged<TimeOfDay> cb) => _tappable(
        onTap: () async {
          final p = await showTimePicker(context: context, initialTime: t);
          if (p != null) cb(p);
        },
        child: Row(children: [
          const Icon(Icons.schedule_rounded, color: _accent, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12))),
          Text(_fmtTime(t),
              style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _tappable({required VoidCallback onTap, required Widget child}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      );

  Widget _submitBtn() => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            disabledBackgroundColor: Colors.grey.shade700,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
              : Text('Rezervasyonu Kaydet',
                  style: GoogleFonts.inter(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      );
}
