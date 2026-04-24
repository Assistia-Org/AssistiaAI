import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/task/task_model.dart';
import '../../providers/task_provider.dart';
import '../../providers/daily_program_provider.dart';

class AddManualTaskPage extends ConsumerStatefulWidget {
  final DateTime initialDate;
  const AddManualTaskPage({super.key, required this.initialDate});

  @override
  ConsumerState<AddManualTaskPage> createState() => _AddManualTaskPageState();
}

class _AddManualTaskPageState extends ConsumerState<AddManualTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedType = 'Görev';
  String _selectedPriority = 'medium';
  late DateTime _selectedDate;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 11, minute: 0);

  final List<String> _types = ['Görev', 'Toplantı', 'Yemek', 'Spor', 'Eğlence', 'Diğer'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('HH:mm').format(dt);
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    final uuid = const Uuid();
    final DateTime combinedStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );

    DateTime combinedEnd = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    // If end time is before start time, it means the task ends the next day
    if (combinedEnd.isBefore(combinedStart)) {
      combinedEnd = combinedEnd.add(const Duration(days: 1));
    }

    final task = TaskModel(
      id: uuid.v4(),
      creatorId: 'user_123', // Hardcoded for now
      assignedTo: ['user_123'],
      type: _selectedType,
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _selectedDate,
      startDate: combinedStart,
      endDate: combinedEnd,
      priority: _selectedPriority,
      status: 'pending',
    );

    try {
      await ref.read(taskControllerProvider).createTask(task);
      
      // Invalidate the daily program provider for the selected date
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      ref.invalidate(dailyProgramByDateProvider(dateStr));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Görev başarıyla eklendi!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(taskLoadingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep dark
      appBar: AppBar(
        title: const Text('Yeni Görev Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
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
              _buildSectionTitle('GÖREV BİLGİLERİ'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _titleController,
                label: 'Başlık',
                hint: 'Örn: Sabah Koşusu',
                icon: Icons.title_rounded,
                validator: (v) => v?.isEmpty ?? true ? 'Başlık gerekli' : null,
              ),
              const SizedBox(height: 16),
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildSectionTitle('ZAMANLAMA'),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildTimePicker('Başlangıç', _startTime, true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTimePicker('Bitiş', _endTime, false)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('DETAYLAR'),
              const SizedBox(height: 16),
              _buildPrioritySelector(),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Açıklama',
                hint: 'Eklemek istediğiniz detaylar...',
                icon: Icons.description_rounded,
                maxLines: 3,
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
          prefixIcon: Icon(icon, color: const Color(0xFF0EA5E9)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          dropdownColor: const Color(0xFF1E293B),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
          isExpanded: true,
          onChanged: (v) => setState(() => _selectedType = v!),
          items: _types.map((t) => DropdownMenuItem(
            value: t,
            child: Row(
              children: [
                 Icon(_getIconForType(t), size: 20, color: _getColorForType(t)),
                 const SizedBox(width: 12),
                 Text(t, style: const TextStyle(color: Colors.white)),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: Color(0xFF0EA5E9)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tarih', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              Text(
                DateFormat('dd MMMM yyyy').format(_selectedDate),
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, bool isStart) {
    return InkWell(
      onTap: () => _selectTime(isStart),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, color: isStart ? const Color(0xFF10B981) : const Color(0xFFF43F5E)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                Row(
                  children: [
                    Text(_formatTime(time), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    if (!isStart && (_endTime.hour < _startTime.hour || (_endTime.hour == _startTime.hour && _endTime.minute < _startTime.minute)))
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '+1 GÜN',
                          style: GoogleFonts.inter(color: const Color(0xFFF43F5E), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final List<String> priorities = ['low', 'medium', 'high'];
    return Row(
      children: priorities.map((p) {
        final isSelected = _selectedPriority == p;
        final color = p == 'high' ? Colors.red : (p == 'medium' ? Colors.orange : Colors.green);
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = p),
            child: Container(
              margin: EdgeInsets.only(right: p != 'high' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? color : Colors.white.withOpacity(0.05)),
              ),
              child: Center(
                child: Text(
                  p.toUpperCase(),
                  style: TextStyle(
                    color: isSelected ? color : Colors.white.withOpacity(0.5),
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveTask,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0EA5E9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Üretim ve Kayıt Et', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Toplantı': return Icons.video_camera_front_rounded;
      case 'Yemek': return Icons.restaurant_rounded;
      case 'Spor': return Icons.fitness_center_rounded;
      case 'Eğlence': return Icons.celebration_rounded;
      case 'Görev': return Icons.task_alt_rounded;
      default: return Icons.event_note_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'Toplantı': return const Color(0xFF8B5CF6);
      case 'Yemek': return const Color(0xFFF59E0B);
      case 'Spor': return const Color(0xFF10B981);
      case 'Eğlence': return const Color(0xFFEC4899);
      case 'Görev': return const Color(0xFF0EA5E9);
      default: return Colors.white54;
    }
  }
}
