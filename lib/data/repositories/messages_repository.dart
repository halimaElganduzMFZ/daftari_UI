import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../models/employee_message.dart';

/// الشكاوى والمقترحات (بديل `sendMessage.php`).
///
/// - `send()`   → `POST /me/messages`            (409 `DUPLICATE_MESSAGE` لنفس النص في اليوم)
/// - `list()`   → `GET  /me/messages?status=&page=&limit=`
/// - `counts()` → `GET  /me/messages/counts`
abstract class MessagesRepository {
  /// الحد الأقصى لنص الرسالة (textarea القديم `maxlength=1500`).
  static const maxLength = 1500;

  Future<SendMessageResult> send(String body);

  Future<MessagesPage> list({
    MessageStatus? status,
    int page = 1,
    int limit = 5,
  });

  Future<MessageCounts> counts();
}

class ApiMessagesRepository implements MessagesRepository {
  const ApiMessagesRepository(this._client);

  final ApiClient _client;

  @override
  Future<SendMessageResult> send(String body) async {
    final json = await _client.postJson(
      '/me/messages',
      body: {'body': body.trim()},
      auth: true,
    );
    return SendMessageResult.fromApi(json);
  }

  @override
  Future<MessagesPage> list({
    MessageStatus? status,
    int page = 1,
    int limit = 5,
  }) async {
    final json = await _client.getJson(
      '/me/messages',
      query: {
        'status': status == null || status == MessageStatus.unknown
            ? 'all'
            : status.name,
        'page': '$page',
        'limit': '${limit.clamp(1, 200)}',
      },
    );
    return MessagesPage.fromApi(json);
  }

  @override
  Future<MessageCounts> counts() async {
    final json = await _client.getJson('/me/messages/counts');
    return MessageCounts.fromApi(json);
  }
}

/// تنفيذ ثابت للتصميم: قائمة في الذاكرة تُحاكي السلوك (إرسال، تكرار، ترقيم).
class StaticMessagesRepository implements MessagesRepository {
  StaticMessagesRepository({
    this.latency = const Duration(milliseconds: 350),
  });

  final Duration latency;

  final List<EmployeeMessage> _items = [
    EmployeeMessage(
      id: 3,
      body: 'مقترح: توفير مواقف مظللة للسيارات بجانب البوابة الشرقية.',
      reply: 'شكراً لمقترحك، تمت إحالته إلى إدارة الخدمات وسيُدرج في خطة العام.',
      sentAt: DateTime(2026, 8, 3),
      state: 3,
      status: MessageStatus.replied,
      statusLabel: EmployeeMessage.defaultLabel(MessageStatus.replied),
    ),
    EmployeeMessage(
      id: 2,
      body: 'شكوى: انقطاع متكرر في تكييف الطابق الثاني خلال ساعات الظهيرة.',
      sentAt: DateTime(2026, 8, 20),
      state: 2,
      status: MessageStatus.read,
      statusLabel: EmployeeMessage.defaultLabel(MessageStatus.read),
    ),
    EmployeeMessage(
      id: 1,
      body: 'مقترح: إتاحة تقديم طلبات الإجازة من التطبيق مباشرة دون الحاجة للمراجعة الورقية.',
      sentAt: DateTime(2026, 9, 12),
      state: 1,
      status: MessageStatus.sent,
      statusLabel: EmployeeMessage.defaultLabel(MessageStatus.sent),
    ),
  ];

  @override
  Future<SendMessageResult> send(String body) async {
    await Future<void>.delayed(latency);
    final text = body.trim();
    if (text.isEmpty || text.length > MessagesRepository.maxLength) {
      throw const ApiException(
        message: 'نص الرسالة مطلوب ولا يتجاوز 1500 حرف',
        statusCode: 400,
      );
    }
    final today = DateTime.now();
    final duplicate = _items.any(
      (m) =>
          m.body == text &&
          m.sentAt != null &&
          m.sentAt!.year == today.year &&
          m.sentAt!.month == today.month &&
          m.sentAt!.day == today.day,
    );
    if (duplicate) {
      throw const ApiException(
        message: 'أرسلت نفس الرسالة اليوم من قبل',
        statusCode: 409,
        code: 'DUPLICATE_MESSAGE',
      );
    }
    final sent = EmployeeMessage(
      id: (_items.map((m) => m.id ?? 0).fold(0, (a, b) => a > b ? a : b)) + 1,
      body: text,
      sentAt: DateTime(today.year, today.month, today.day),
      state: 1,
      status: MessageStatus.sent,
      statusLabel: EmployeeMessage.defaultLabel(MessageStatus.sent),
    );
    _items.add(sent);
    return SendMessageResult(sent: sent, message: 'تم إرسال رسالتك بنجاح');
  }

  @override
  Future<MessagesPage> list({
    MessageStatus? status,
    int page = 1,
    int limit = 5,
  }) async {
    await Future<void>.delayed(latency);
    final filtered = [
      for (final m in _items)
        if (status == null || m.status == status) m,
    ]..sort((a, b) {
        final byDate = (b.sentAt ?? DateTime(0)).compareTo(a.sentAt ?? DateTime(0));
        return byDate != 0 ? byDate : (b.id ?? 0).compareTo(a.id ?? 0);
      });
    final start = (page - 1) * limit;
    final slice = start >= filtered.length
        ? const <EmployeeMessage>[]
        : filtered.sublist(start, (start + limit).clamp(0, filtered.length));
    return MessagesPage(
      items: slice,
      page: page,
      hasNext: start + limit < filtered.length,
    );
  }

  @override
  Future<MessageCounts> counts() async {
    await Future<void>.delayed(latency ~/ 2);
    int count(MessageStatus s) => _items.where((m) => m.status == s).length;
    return MessageCounts(
      total: _items.length,
      sent: count(MessageStatus.sent),
      read: count(MessageStatus.read),
      replied: count(MessageStatus.replied),
    );
  }
}
