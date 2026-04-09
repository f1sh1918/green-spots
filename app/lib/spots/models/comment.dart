class Comment {
  final int id;
  final int postId;
  final int authorId;
  final String authorName;
  final String content;
  final String date;
  final String status;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.date,
    required this.status,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      postId: json['post'],
      authorId: json['author'] ?? 0,
      authorName: json['author_name'] ?? '',
      content: _stripHtml(json['content']?['rendered'] ?? ''),
      date: json['date'] ?? '',
      status: json['status'] ?? '',
    );
  }

  static String _stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .trim();
  }
}
