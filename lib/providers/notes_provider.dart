import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotesProvider extends ChangeNotifier {
  final notes = <Map<String, dynamic>>[];
  bool loading = false;

  Future<void> getNotes(String uid) async {
    loading = true;
    notifyListeners();

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notes")
        .orderBy("createdAt", descending: true)
        .get();

    notes.clear();
    notes.addAll(snap.docs.map((d) => {"id": d.id, ...d.data()}));

    loading = false;
    notifyListeners();
  }

  Future<void> updateTextNote(String userId, String noteId, String newText) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("notes")
          .doc(noteId)
          .update({
        "text": newText,
        "updatedAt": DateTime.now(),
      });

      // refresh notes
      await getNotes(userId);
      notifyListeners();

    } catch (e) {
      print("Error updating text note: $e");
    }
  }

  Future<void> updateDrawingNote(String userId, String noteId, Uint8List newImage) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("notes")
          .doc(noteId)
          .update({
        "image": newImage,
        "updatedAt": DateTime.now(),
      });

      await getNotes(userId);
      notifyListeners();

    } catch (e) {
      print("Error updating drawing note: $e");
    }
  }


  Future<void> addTextNote(String uid, String text) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notes")
        .add({
      "type": "text",
      "text": text,
      "createdAt": Timestamp.now(),
    });

    await getNotes(uid);
  }

  Future<void> addDrawingNote(String uid, Uint8List bytes) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notes")
        .add({
      "type": "drawing",
      "image": bytes,
      "createdAt": Timestamp.now(),
    });

    await getNotes(uid);
  }

  Future<void> deleteNote(String uid, String noteId) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notes")
        .doc(noteId)
        .delete();

    await getNotes(uid);
  }
}
