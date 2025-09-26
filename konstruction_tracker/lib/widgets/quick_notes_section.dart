import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../models/project.dart';

class QuickNotesSection extends StatefulWidget {
  final Project project;
  final VoidCallback? onRefresh;

  const QuickNotesSection({
    Key? key,
    required this.project,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<QuickNotesSection> createState() => _QuickNotesSectionState();
}

class _QuickNotesSectionState extends State<QuickNotesSection> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _noteController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final success = await firestoreService.addProjectNote(
      widget.project.id,
      _noteController.text.trim(),
    );

    if (success) {
      _noteController.clear();
      widget.onRefresh?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Note added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add note'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _toggleNote(String noteId) async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final success = await firestoreService.toggleProjectNote(widget.project.id, noteId);
    
    if (success) {
      widget.onRefresh?.call();
    }
  }

  Future<void> _editNote(String noteId, String currentText) async {
    _editController.text = currentText;
    
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: _editController,
          decoration: const InputDecoration(
            hintText: 'Enter note text',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _editController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newText != null && newText.isNotEmpty && newText != currentText) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final success = await firestoreService.updateProjectNote(
        widget.project.id,
        noteId,
        newText,
      );
      
      if (success) {
        widget.onRefresh?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update note'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      final success = await firestoreService.deleteProjectNote(
        widget.project.id,
        noteId,
      );
      
      if (success) {
        widget.onRefresh?.call();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete note'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('📝 QuickNotesSection: Project notes count: ${widget.project.notes.length}');
      for (int i = 0; i < widget.project.notes.length; i++) {
        final note = widget.project.notes[i];
        print('📝 Note $i: ${note['text']} (completed: ${note['isCompleted']})');
      }
    }
    
    final activeNotes = widget.project.notes
        .where((note) => !(note['isCompleted'] ?? false))
        .toList();
        
    if (kDebugMode) {
      print('📝 Active notes count: ${activeNotes.length}');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.note_alt,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Add Note Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _noteController,
                    decoration: const InputDecoration(
                      hintText: 'Add a quick note...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    maxLines: 1,
                    onSubmitted: (_) => _addNote(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addNote,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            
            if (activeNotes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              
              // Notes List
              ...activeNotes.map((note) => _buildNoteCard(note)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    final noteId = note['id'] as String;
    final noteText = note['text'] as String;
    final isCompleted = note['isCompleted'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isCompleted,
              onChanged: (_) => _toggleNote(noteId),
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            
            // Note Text
            Expanded(
              child: Text(
                noteText,
                style: TextStyle(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted ? Colors.grey : null,
                ),
              ),
            ),
            
            // Action Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _editNote(noteId, noteText),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Edit note',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteNote(noteId),
                  icon: const Icon(Icons.delete, size: 18),
                  tooltip: 'Delete note',
                  color: Colors.red,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
