import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/daily_program_provider.dart';

class AddManualHotelPage extends ConsumerStatefulWidget {
  const AddManualHotelPage({super.key});

  @override
  ConsumerState<AddManualHotelPage> createState() => _AddManualHotelPageState();
}

class _AddManualHotelPageState extends ConsumerState<AddManualHotelPage> {
  final _formKey = GlobalKey<FormState>();
  final _hotelNameController = TextEditingController();
  final _pnrController = TextEditingController();
  final _guestController = TextEditingController();
  
  String _selectedCity = 'İstanbul';
  static const List<String> _cities = [
    "Adana", "Adıyaman", "Afyonkarahisar", "Ağrı", "Aksaray", "Amasya", "Ankara", "Antalya", "Ardahan", "Artvin", 
    "Aydın", "Balıkesir", "Bartın", "Batman", "Bayburt", "Bilecik", "Bingöl", "Bitlis", "Bolu", "Burdur", 
    "Bursa", "Çanakkale", "Çankırı", "Çorum", "Denizli", "Diyarbakır", "Düzce", "Edirne", "Elazığ", "Erzincan", 
    "Erzurum", "Eskişehir", "Gaziantep", "Giresun", "Gümüşhane", "Hakkari", "Hatay", "Iğdır", "Isparta", "İstanbul", 
    "İzmir", "Kahramanmaraş", "Karabük", "Karaman", "Kars", "Kastamonu", "Kayseri", "Kırıkkale", "Kırklareli", "Kırşehir", 
    "Kilis", "Kocaeli", "Konya", "Kütahya", "Malatya", "Manisa", "Mardin", "Mersin", "Muğla", "Muş", 
    "Nevşehir", "Niğde", "Ordu", "Osmaniye", "Rize", "Sakarya", "Samsun", "Siirt", "Sinop", "Sivas", 
    "Şanlıurfa", "Şırnak", "Tekirdağ", "Tokat", "Trabzon", "Tunceli", "Uşak", "Van", "Yalova", "Yozgat", "Zonguldak"
  ];
  
  late DateTime _checkInDate;
  late DateTime _checkOutDate;
  TimeOfDay _checkInTime = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _checkOutTime = const TimeOfDay(hour: 11, minute: 0);

  @override
  void initState() {
    super.initState();
    _checkInDate = DateTime.now();
    _checkOutDate = DateTime.now().add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    _pnrController.dispose();
    _guestController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkInDate : _checkOutDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInDate = picked;
          if (_checkOutDate.isBefore(_checkInDate)) {
            _checkOutDate = _checkInDate.add(const Duration(days: 1));
          }
        } else {
          _checkOutDate = picked;
        }
      });
    }
  }

  Future<void> _selectTime(bool isCheckIn) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isCheckIn ? _checkInTime : _checkOutTime,
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkInTime = picked;
        } else {
          _checkOutTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) return;

    final uuid = const Uuid();
    
    final details = {
      "hotel_name": _hotelNameController.text,
      "address": _selectedCity,
      "check_in": DateFormat('yyyy-MM-dd').format(_checkInDate),
      "check_out": DateFormat('yyyy-MM-dd').format(_checkOutDate),
      "check_in_time": _formatTime(_checkInTime),
      "check_out_time": _formatTime(_checkOutTime),
      "pnr": _pnrController.text,
      "guest": _guestController.text,
      "status": "confirmed"
    };

    final DateTime combinedStart = DateTime(
      _checkInDate.year,
      _checkInDate.month,
      _checkInDate.day,
      _checkInTime.hour,
      _checkInTime.minute,
    );

    final DateTime combinedEnd = DateTime(
      _checkOutDate.year,
      _checkOutDate.month,
      _checkOutDate.day,
      _checkOutTime.hour,
      _checkOutTime.minute,
    );

    final reservation = Reservation(
      id: uuid.v4(),
      category: "hotel",
      title: "Otel: ${_hotelNameController.text}",
      details: details,
      startDate: combinedStart,
      endDate: combinedEnd,
      status: "confirmed",
    );

    try {
      await ref.read(reservationControllerProvider).addReservation(reservation);
      final dateStr = DateFormat('yyyy-MM-dd').format(_checkInDate);
      ref.invalidate(dailyProgramByDateProvider(dateStr));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Otel rezervasyonu başarıyla eklendi!'),
            backgroundColor: Color(0xFF6366F1),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(reservationLoadingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep dark
      appBar: AppBar(
        title: const Text('Manuel Otel Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('OTEL BİLGİLERİ'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _hotelNameController,
                label: 'Otel Adı*',
                hint: 'Örn: Hilton Istanbul',
                icon: Icons.hotel_rounded,
                validator: (v) => v?.trim().isEmpty ?? true ? 'Otel adı gerekli' : null,
              ),
              const SizedBox(height: 16),
              _buildCitySelector(),
              const SizedBox(height: 24),
              
              _buildSectionTitle('ÇIKIŞ BİLGİLERİ (GİRİŞ - ÇIKIŞ)'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildDateTimePicker('Giriş', _checkInDate, _checkInTime, true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildDateTimePicker('Çıkış', _checkOutDate, _checkOutTime, false)),
                ],
              ),
              const SizedBox(height: 24),
              
              _buildSectionTitle('DETAYLAR'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _pnrController,
                label: 'Rezervasyon No (PNR)',
                hint: 'Örn: XTZ123',
                icon: Icons.confirmation_number_rounded,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _guestController,
                label: 'Misafir(ler)',
                hint: 'Örn: Ahmet Yılmaz',
                icon: Icons.person_rounded,
              ),
              const SizedBox(height: 40),
              _buildSubmitButton(isLoading),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: Icon(icon, color: const Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildCitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_rounded, color: Color(0xFF6366F1)),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCity,
                dropdownColor: const Color(0xFF1E293B),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
                isExpanded: true,
                onChanged: (v) => setState(() => _selectedCity = v!),
                menuMaxHeight: 300,
                items: _cities.map((city) => DropdownMenuItem(
                  value: city,
                  child: Text(city, style: const TextStyle(color: Colors.white)),
                )).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker(String label, DateTime date, TimeOfDay time, bool isCheckIn) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isCheckIn ? Icons.login_rounded : Icons.logout_rounded, 
                  color: isCheckIn ? const Color(0xFF10B981) : const Color(0xFFF43F5E), size: 16),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _selectDate(isCheckIn),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_rounded, color: Color(0xFF6366F1), size: 16),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy').format(date),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _selectTime(isCheckIn),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Color(0xFF6366F1), size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatTime(time),
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6366F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
