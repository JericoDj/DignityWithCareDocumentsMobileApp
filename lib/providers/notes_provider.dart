import 'dart:convert';
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

    // Decode Base64 images
    for (var doc in snap.docs) {
      final data = doc.data();
      final id = doc.id;

      if (data["type"] == "drawing" && data["image"] is String) {
        data["image"] = base64Decode(data["image"]);
      }

      notes.add({"id": id, ...data});
    }

    loading = false;
    notifyListeners();
  }

  Future<void> updateTextNote(
      String userId, String noteId, String newText) async {
    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("notes")
          .doc(noteId)
          .update({
        "text": newText,
        "updatedAt": Timestamp.now(),
      });

      await getNotes(userId);
    } catch (e) {
      print("Error updating text note: $e");
    }
  }

  Future<void> updateDrawingNote(
      String userId, String noteId, Uint8List newImage) async {
    try {
      final base64Image = base64Encode(newImage);

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("notes")
          .doc(noteId)
          .update({
        "image": base64Image,
        "updatedAt": Timestamp.now(),
      });

      await getNotes(userId);
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
    final base64Image = base64Encode(bytes);

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("notes")
        .add({
      "type": "drawing",
      "image": base64Image,
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
