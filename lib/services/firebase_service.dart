import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ppb_awesome_notification/models/task.dart';
import 'package:ppb_awesome_notification/services/notification_service.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collectionName = 'tasks';

  Stream<List<Task>> getTasks() {
    return _db.collection(_collectionName).orderBy('reminderDateTime').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList());
  }

  Future<DocumentReference> addTask(Task task) async {
    DocumentReference docRef = await _db.collection(_collectionName).add(task.toMap());
    // Update task dengan ID yang baru dibuat oleh Firebase untuk keperluan notifikasi
    task.id = docRef.id;
    await NotificationService.scheduleNotification(task);
    // Update field notificationId di Firestore jika perlu
    await docRef.update({'notificationId': task.notificationId});
    return docRef;
  }

  Future<void> updateTask(Task task) async {
    if (task.id == null) return;

    // Jika task sudah ada notifikasi sebelumnya, cancel dulu
    if (task.notificationId != null) {
      await NotificationService.cancelNotification(task.notificationId);
    }
    // Jadwalkan notifikasi baru
    await NotificationService.scheduleNotification(task);
    // Update task di Firestore, termasuk notificationId yang mungkin baru
    await _db.collection(_collectionName).doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(Task task) async {
    if (task.id == null) return;
    await _db.collection(_collectionName).doc(task.id).delete();
    if (task.notificationId != null) {
      await NotificationService.cancelNotification(task.notificationId);
    }
  }

    Future<void> toggleTaskDone(Task task) async {
    if (task.id == null) return;

    // Simpan state isDone sebelumnya untuk logika notifikasi
    bool wasPreviouslyDone = task.isCompleted ?? false;
    task.isCompleted = !(task.isCompleted ?? false); // Toggle status

    await _db.collection(_collectionName).doc(task.id).update({'isDone': task.isCompleted});

    if (task.isCompleted == true) {
      // Task BARU SAJA ditandai selesai
      if (task.notificationId != null) {
        await NotificationService.cancelNotification(task.notificationId);
        // Opsional: Anda bisa set task.notificationId menjadi null di sini dan update Firestore
        // jika Anda tidak ingin menyimpan ID notifikasi yang sudah di-cancel.
        // task.notificationId = null;
        // await _db.collection(_collectionName).doc(task.id).update({'notificationId': null});
      }
      // Kirim notifikasi bahwa task telah selesai
      await NotificationService.sendTaskCompletedNotification(task); // <--- PANGGIL DI SINI
    } else if (wasPreviouslyDone && task.isCompleted == true) {
      // Task BARU SAJA ditandai BELUM selesai (sebelumnya selesai)
      // Jadwalkan ulang notifikasi reminder jika waktunya belum lewat
      if (task.reminderDateTime.isAfter(DateTime.now())) {
        await NotificationService.scheduleNotification(task);
        // Update notificationId di Firestore (karena scheduleNotification bisa menghasilkan ID baru jika sebelumnya null)
        await _db.collection(_collectionName).doc(task.id).update({'notificationId': task.notificationId});
      }
    }
  }
}