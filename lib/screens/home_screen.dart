import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ppb_awesome_notification/models/task.dart';
import 'package:ppb_awesome_notification/services/firebase_service.dart';
import 'package:ppb_awesome_notification/screens/add_edit_task_screen.dart';
import 'package:ppb_awesome_notification/services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void initState() {
    super.initState();
    NotificationService.listenToNotifications(); // Mulai mendengarkan aksi notifikasi
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Tracker'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Task>>(
        stream: _firebaseService.getTasks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Tidak ada task. Tambahkan satu!'));
          }

          List<Task> tasks = snapshot.data!;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              Task task = tasks[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                    task.title ?? '',
                    style: TextStyle(
                      decoration: task.isCompleted == 1 ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Text(
                    'Reminder: ${DateFormat('dd MMM yyyy, HH:mm').format(task.reminderDateTime)}'
                    '${task.description != null && task.description!.isNotEmpty ? "\n${task.description}" : ""}',
                    style: TextStyle(
                      decoration: task.isCompleted == 1 ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  leading: Checkbox(
                    value: task.isCompleted,
                    onChanged: (bool? value) {
                      _firebaseService.toggleTaskDone(task);
                    },
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddEditTaskScreen(task: task),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          // Konfirmasi sebelum hapus
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Hapus Task'),
                                content: Text('Anda yakin ingin menghapus task "${task.title}"?'),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirm == true) {
                            await _firebaseService.deleteTask(task);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Task "${task.title}" dihapus')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () { // Bisa juga untuk navigasi ke detail atau edit
                     Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => AddEditTaskScreen(task: task),
                        ),
                      );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddEditTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Tambah Task',
      ),
    );
  }
}