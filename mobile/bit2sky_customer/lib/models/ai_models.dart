/// AI Copilot (Wellio) models — comms.ai_sessions / ai_chat_messages.
library;

enum AiRole { user, assistant, system }

AiRole parseRole(String? r) {
  switch (r) {
    case 'Assistant':
      return AiRole.assistant;
    case 'System':
      return AiRole.system;
    default:
      return AiRole.user;
  }
}

class AiMessage {
  final String id;
  final AiRole role;
  final String content;
  final String createdAt;

  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt = '',
  });

  bool get isUser => role == AiRole.user;

  factory AiMessage.fromJson(Map<String, dynamic> j) => AiMessage(
        id: (j['id'] ?? '').toString(),
        role: parseRole(j['role']?.toString()),
        content: (j['content'] ?? '').toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );
}

class AiSession {
  final String id;
  final String? title;
  const AiSession({required this.id, this.title});

  factory AiSession.fromJson(Map<String, dynamic> j) => AiSession(
        id: (j['id'] ?? '').toString(),
        title: j['title']?.toString(),
      );
}
