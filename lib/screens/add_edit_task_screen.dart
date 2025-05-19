import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ppb_awesome_notification/models/task.dart';
import 'package:ppb_awesome_notification/services/firebase_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task; // Nullable, jika null berarti 'Add', jika ada berarti 'Edit'

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _selectedDateTime;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _selectedDateTime = widget.task?.reminderDateTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now().add(const Duration(minutes: 5)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now().add(const Duration(minutes: 5))),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDateTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan pilih waktu pengingat')),
        );
        return;
      }

      if (_selectedDateTime!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waktu pengingat harus di masa depan (minimal 1 menit dari sekarang)')),
        );
        return;
      }


      final taskData = Task(
        id: widget.task?.id, // Pertahankan ID jika sedang mengedit
        title: _titleController.text,
        description: _descriptionController.text,
        reminderDateTime: _selectedDateTime!,
        isCompleted: widget.task?.isCompleted ?? false,
        notificationId: widget.task?.notificationId // Pertahankan notificationId jika ada
      );

      try {
        if (_isEditing) {
          await _firebaseService.updateTask(taskData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task berhasil diperbarui!')),
          );
        } else {
          await _firebaseService.addTask(taskData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Task berhasil ditambahkan!')),
          );
        }
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'Tambah Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul Task'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Deskripsi (Opsional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDateTime == null
                          ? 'Pilih Waktu Pengingat'
                          : 'Pengingat: ${DateFormat('dd MMM yyyy, HH:mm').format(_selectedDateTime!)}',
                    ),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pilih'),
                    onPressed: _pickDateTime,
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(_isEditing ? 'Simpan Perubahan' : 'Simpan Task'),
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}