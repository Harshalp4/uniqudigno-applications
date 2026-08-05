/// Support ticket models — comms.support_tickets / support_messages.
library;

class SupportTicket {
  final String id;
  final String ticketNumber;
  final String subject;
  final String category;
  final String status;
  final String createdAt;

  const SupportTicket({
    required this.id,
    required this.ticketNumber,
    required this.subject,
    required this.category,
    required this.status,
    required this.createdAt,
  });

  bool get isClosed => status == 'Closed' || status == 'Resolved';

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
        id: (j['id'] ?? '').toString(),
        ticketNumber: (j['ticketNumber'] ?? '').toString(),
        subject: (j['subject'] ?? '').toString(),
        category: (j['category'] ?? 'general').toString(),
        status: (j['status'] ?? 'Open').toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );
}

class SupportMessage {
  final String id;
  final bool isFromAgent;
  final String body;
  final String createdAt;

  const SupportMessage({
    required this.id,
    required this.isFromAgent,
    required this.body,
    required this.createdAt,
  });

  factory SupportMessage.fromJson(Map<String, dynamic> j) => SupportMessage(
        id: (j['id'] ?? '').toString(),
        isFromAgent: (j['isFromAgent'] ?? false) as bool,
        body: (j['body'] ?? '').toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );
}
