import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notes_provider.dart';
import 'drawing_screen.dart';

class MyNotesScreen extends StatefulWidget {
  final String userId;
  const MyNotesScreen({super.key, required this.userId});

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen> {
  bool selectionMode = false;
  final Set<String> selectedNotes = {};

  void toggleSelectionMode() {
    setState(() {
      selectionMode = !selectionMode;
      selectedNotes.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();

    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 800 ? 6 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        actions: [
          if (!selectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: toggleSelectionMode,
            )
          else
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                final provider = context.read<NotesProvider>();
                for (var id in selectedNotes) {
                  provider.deleteNote(widget.userId, id);
                }
                toggleSelectionMode();
              },
            ),
        ],
      ),

      floatingActionButton: selectionMode
          ? null
          : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "text",
            child: const Icon(Icons.text_fields),
            onPressed: () async {
              final text = await showDialog<String>(
                context: context,
                builder: (_) => const _AddOrEditTextNoteDialog(),
              );
              if (text != null && text.trim().isNotEmpty) {
                notesProvider.addTextNote(widget.userId, text.trim());
              }
            },
          ),
          const SizedBox(height: 12),

          FloatingActionButton(
            heroTag: "pen",
            child: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DrawingScreen(),
                ),
              );
              if (result != null && result is Uint8List) {
                notesProvider.addDrawingNote(widget.userId, result);
              }
            },
          ),
        ],
      ),

      body: Column(
        children: [
          ElevatedButton(
            onPressed: () => notesProvider.getNotes(widget.userId),
            child: const Text("Get My Notes"),
          ),

          Expanded(
            child: notesProvider.loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemCount: notesProvider.notes.length,
              itemBuilder: (_, i) {
                final note = notesProvider.notes[i];
                return _buildNoteItem(context, note);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(BuildContext context, Map<String, dynamic> note) {
    final id = note["id"];
    final selected = selectedNotes.contains(id);

    return GestureDetector(
      onLongPress: () {
        if (!selectionMode) {
          setState(() {
            selectionMode = true;
            selectedNotes.add(id); // auto-select the long-pressed item
          });
        }
      },

      onTap: () async {
        if (selectionMode) {
          setState(() {
            selected
                ? selectedNotes.remove(id)
                : selectedNotes.add(id);
          });
          return;
        }

        // EDIT NOTE (same behavior as before)
        if (note["type"] == "text") {
          final updated = await showDialog<String>(
            context: context,
            builder: (_) => _AddOrEditTextNoteDialog(
              initialText: note["text"],
            ),
          );

          if (updated != null) {
            context.read<NotesProvider>().updateTextNote(
              widget.userId,
              id,
              updated,
            );
          }
        } else {
          final bytes = Uint8List.fromList(List<int>.from(note["image"]));
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DrawingScreen(initialImage: bytes),
            ),
          );

          if (updated != null) {
            context.read<NotesProvider>().updateDrawingNote(
              widget.userId,
              id,
              updated,
            );
          }
        }
      },

      child: Stack(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: note["type"] == "text"
                  ? Text(note["text"], style: const TextStyle(fontSize: 16))
                  : Image.memory(
                Uint8List.fromList(List<int>.from(note["image"])),
                fit: BoxFit.cover,
              ),
            ),
          ),

          if (selectionMode)
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: selected ? Colors.red : Colors.grey,
              ),
            ),
        ],
      ),
    );
  }

}

class _AddOrEditTextNoteDialog extends StatefulWidget {
  final String? initialText;
  const _AddOrEditTextNoteDialog({this.initialText});

  @override
  State<_AddOrEditTextNoteDialog> createState() =>
      _AddOrEditTextNoteDialogState();
}

class _AddOrEditTextNoteDialogState
    extends State<_AddOrEditTextNoteDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialText);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialText == null ? "Add Note" : "Edit Note"),
      content: TextField(
        controller: controller,
        maxLines: 6,
        decoration: const InputDecoration(
          hintText: "Type something...",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text("Save"),
        ),
      ],
    );
  }
}
