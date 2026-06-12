enum ChatAuthor { user, bot }

class ChatMessage {
  const ChatMessage({
    required this.author,
    required this.text,
    required this.createdAt,
  });

  final ChatAuthor author;
  final String text;
  final DateTime createdAt;
}
