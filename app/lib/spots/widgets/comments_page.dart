import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spots/auth/models/settings.dart';
import 'package:spots/spots/models/comment.dart';
import 'package:spots/spots/services/comment_service.dart';
import 'package:spots/utils/messenger_utils.dart';

class CommentsPage extends StatefulWidget {
  final int spotId;
  final String spotTitle;

  const CommentsPage({
    required this.spotId,
    required this.spotTitle,
    super.key,
  });

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  final _service = CommentService();
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  int? _editingCommentId;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final comments = await _service.fetchComments(widget.spotId);
      if (mounted) setState(() => _comments = comments);
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitComment(String token) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() => _submitting = true);
    try {
      if (_editingCommentId != null) {
        final updated = await _service.updateComment(
          commentId: _editingCommentId!,
          content: text,
          token: token,
        );
        if (mounted) {
          setState(() {
            final idx = _comments.indexWhere((c) => c.id == _editingCommentId);
            if (idx != -1) _comments[idx] = updated;
            _editingCommentId = null;
            _textController.clear();
          });
        }
      } else {
        final comment = await _service.postComment(
          postId: widget.spotId,
          content: text,
          token: token,
        );
        if (mounted) {
          setState(() {
            _comments.insert(0, comment);
            _textController.clear();
          });
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString(), Colors.red);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deleteComment(int commentId, String token) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kommentar löschen'),
        content: Text('Möchtest du diesen Kommentar wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteComment(commentId: commentId, token: token);
      if (mounted) {
        setState(() => _comments.removeWhere((c) => c.id == commentId));
      }
    } catch (e) {
      if (mounted) showSnackBar(context, e.toString(), Colors.red);
    }
  }

  void _startEditing(Comment comment) {
    setState(() {
      _editingCommentId = comment.id;
      _textController.text = comment.content;
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingCommentId = null;
      _textController.clear();
    });
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsModel>(context, listen: false);
    final token = settings.token;
    final currentUserId = settings.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Kommentare'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                ? Center(
                    child: Text(
                      'Noch keine Kommentare.\nSchreib den Ersten!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadComments,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      itemCount: _comments.length,
                      itemBuilder: (context, index) {
                        final comment = _comments[index];
                        final isOwn =
                            currentUserId != null &&
                            comment.authorId.toString() == currentUserId;
                        return _CommentTile(
                          comment: comment,
                          isOwn: isOwn,
                          isEditing: _editingCommentId == comment.id,
                          formattedDate: _formatDate(comment.date),
                          onEdit: () => _startEditing(comment),
                          onDelete: token != null
                              ? () => _deleteComment(comment.id, token)
                              : null,
                        );
                      },
                    ),
                  ),
          ),
          if (token != null) ...[
            Divider(height: 1),
            _CommentInput(
              controller: _textController,
              submitting: _submitting,
              isEditing: _editingCommentId != null,
              onSubmit: () => _submitComment(token),
              onCancelEdit: _cancelEditing,
            ),
          ] else ...[
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Melde dich an, um einen Kommentar zu schreiben.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool isOwn;
  final bool isEditing;
  final String formattedDate;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _CommentTile({
    required this.comment,
    required this.isOwn,
    required this.isEditing,
    required this.formattedDate,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      color: isEditing
          ? Theme.of(
              context,
            ).colorScheme.primaryContainer.withValues(alpha: 0.4)
          : null,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.authorName,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        formattedDate,
                        style: Theme.of(
                          context,
                        ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (isOwn) ...[
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, size: 18),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Bearbeiten',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: 18, color: Colors.red),
                    onPressed: onDelete,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Löschen',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CommentInput extends StatelessWidget {
  final TextEditingController controller;
  final bool submitting;
  final bool isEditing;
  final VoidCallback onSubmit;
  final VoidCallback onCancelEdit;

  const _CommentInput({
    required this.controller,
    required this.submitting,
    required this.isEditing,
    required this.onSubmit,
    required this.onCancelEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isEditing) ...[
              Row(
                children: [
                  Icon(Icons.edit, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Kommentar bearbeiten',
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: Colors.grey),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: onCancelEdit,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    child: Text('Abbrechen'),
                  ),
                ],
              ),
              SizedBox(height: 4),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: isEditing
                          ? 'Kommentar bearbeiten...'
                          : 'Kommentar schreiben...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
                SizedBox(width: 8),
                submitting
                    ? SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        onPressed: onSubmit,
                        icon: Icon(
                          isEditing ? Icons.check : Icons.send,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        tooltip: isEditing ? 'Speichern' : 'Senden',
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
