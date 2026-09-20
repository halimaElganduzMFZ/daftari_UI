/// حالة المراسلة كما فسّرتها الصفحة القديمة (`messages_and_proposals.state`):
/// 1 مُرسلة ولم تُقرأ · 2 قرأتها الموارد البشرية · 3 تم الرد.
enum MessageStatus { sent, read, replied, unknown }

/// شكوى أو مقترح أرسله الموظف (مقابل `MessageDto` من `GET /me/messages`).
class EmployeeMessage {
  const EmployeeMessage({
    required this.id,
    required this.body,
    required this.status,
    required this.statusLabel,
    this.reply,
    this.sentAt,
    this.state,
  });

  /// معرّف الصف؛ `null` عندما يعوز الجدول القديم مفتاحاً أساسياً.
  final int? id;
  final String body;

  /// ردّ الموارد البشرية (`replay`)، `null` حتى يُجاب.
  final String? reply;

  /// يوم الإرسال (`enterDate`).
  final DateTime? sentAt;

  /// القيمة الخام للحالة.
  final int? state;
  final MessageStatus status;

  /// نص «حالة المراسلة» القديم.
  final String statusLabel;

  bool get hasReply => (reply ?? '').trim().isNotEmpty;

  /// مفتاح ثابت للقوائم حتى مع غياب `id`.
  String get key => id?.toString() ?? '${sentAt?.toIso8601String()}|${body.hashCode}';

  static MessageStatus statusFromApi(String? raw) => switch (raw) {
        'sent' => MessageStatus.sent,
        'read' => MessageStatus.read,
        'replied' => MessageStatus.replied,
        _ => MessageStatus.unknown,
      };

  static String defaultLabel(MessageStatus status) => switch (status) {
        MessageStatus.sent => 'تم الإرسال والحالة غير مقروءة',
        MessageStatus.read => 'تم الإرسال والحالة مقروءة',
        MessageStatus.replied => 'تم الرد',
        MessageStatus.unknown => 'غير معروف',
      };

  /// تسمية مختصرة للشارة.
  static String shortLabel(MessageStatus status) => switch (status) {
        MessageStatus.sent => 'بانتظار القراءة',
        MessageStatus.read => 'مقروءة',
        MessageStatus.replied => 'تم الرد',
        MessageStatus.unknown => 'غير معروف',
      };

  factory EmployeeMessage.fromApi(Map<String, dynamic> json) {
    final status = statusFromApi(json['status'] as String?);
    final sentRaw = json['sentAt'];
    return EmployeeMessage(
      id: (json['id'] as num?)?.toInt(),
      body: (json['body'] as String?) ?? '',
      reply: json['reply'] as String?,
      sentAt: sentRaw is String ? DateTime.tryParse(sentRaw) : null,
      state: (json['state'] as num?)?.toInt(),
      status: status,
      statusLabel: (json['statusLabel'] as String?)?.trim().isNotEmpty == true
          ? (json['statusLabel'] as String).trim()
          : defaultLabel(status),
    );
  }
}

/// عدّادات الرسائل حسب الحالة (`MessageCountsDto`).
class MessageCounts {
  const MessageCounts({
    required this.total,
    required this.sent,
    required this.read,
    required this.replied,
  });

  final int total;
  final int sent;
  final int read;
  final int replied;

  static const zero = MessageCounts(total: 0, sent: 0, read: 0, replied: 0);

  int of(MessageStatus? status) => switch (status) {
        null => total,
        MessageStatus.sent => sent,
        MessageStatus.read => read,
        MessageStatus.replied => replied,
        MessageStatus.unknown => 0,
      };

  factory MessageCounts.fromApi(Map<String, dynamic> json) => MessageCounts(
        total: (json['total'] as num?)?.toInt() ?? 0,
        sent: (json['sent'] as num?)?.toInt() ?? 0,
        read: (json['read'] as num?)?.toInt() ?? 0,
        replied: (json['replied'] as num?)?.toInt() ?? 0,
      );
}

/// صفحة من قائمة الرسائل (`{ data, meta }`).
class MessagesPage {
  const MessagesPage({
    required this.items,
    required this.page,
    required this.hasNext,
  });

  final List<EmployeeMessage> items;
  final int page;
  final bool hasNext;

  factory MessagesPage.fromApi(Map<String, dynamic> json) {
    final meta = json['meta'] is Map<String, dynamic>
        ? json['meta'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return MessagesPage(
      items: [
        for (final item in (json['data'] as List?) ?? const [])
          if (item is Map<String, dynamic>) EmployeeMessage.fromApi(item),
      ],
      page: (meta['page'] as num?)?.toInt() ?? 1,
      hasNext: meta['hasNext'] as bool? ?? false,
    );
  }
}

/// نتيجة الإرسال (`SendMessageResultDto`).
class SendMessageResult {
  const SendMessageResult({required this.sent, required this.message});

  final EmployeeMessage sent;

  /// نص التأكيد القديم: «تم إرسال رسالتك بنجاح».
  final String message;

  factory SendMessageResult.fromApi(Map<String, dynamic> json) {
    final sent = json['sent'];
    return SendMessageResult(
      sent: sent is Map<String, dynamic>
          ? EmployeeMessage.fromApi(sent)
          : EmployeeMessage(
              id: null,
              body: '',
              status: MessageStatus.sent,
              statusLabel: EmployeeMessage.defaultLabel(MessageStatus.sent),
            ),
      message: (json['message'] as String?) ?? 'تم إرسال رسالتك بنجاح',
    );
  }
}
