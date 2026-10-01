import 'dart:io';

/// وسيط تطوير للويب فقط.
///
/// المتصفح يمنع طلبات الواجهة (منفذ التطبيق) إلى
/// `http://10.10.10.97:3000` لأن الاستجابة لا تحتوي
/// `Access-Control-Allow-Origin`، فيظهر `Failed to fetch`.
///
/// هذا الوسيط يستمع على كل واجهات الجهاز (`0.0.0.0`) ويمرّر
/// `/api/...` إلى خادم المكتب، ويضيف ترويسات CORS حتى ينجح
/// الدخول من هذا الجهاز ومن أي جهاز آخر على الشبكة.
///
/// ```
/// dart run tool/web_api_proxy.dart
/// ```
Future<void> main(List<String> args) async {
  final port =
      int.tryParse(_arg(args, '--port') ?? '') ??
      int.tryParse(Platform.environment['WEB_API_PROXY_PORT'] ?? '') ??
      43124;
  final upstream = Uri.parse(
    _arg(args, '--upstream') ??
        Platform.environment['API_UPSTREAM'] ??
        'http://10.10.10.97:3000',
  );

  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  final client = HttpClient()..autoUncompress = false;

  stdout.writeln('API proxy  0.0.0.0:$port  ->  $upstream');
  stdout.writeln('App URL    http://<device-ip>:43123');

  await for (final request in server) {
    try {
      await _forward(client, request, upstream);
    } catch (error) {
      stderr.writeln('proxy: $error');
      try {
        _cors(request);
        request.response.statusCode = HttpStatus.badGateway;
        request.response.headers.contentType = ContentType.text;
        request.response.write('Bad gateway');
        await request.response.close();
      } catch (_) {}
    }
  }
}

Future<void> _forward(
  HttpClient client,
  HttpRequest incoming,
  Uri upstream,
) async {
  if (incoming.method == 'OPTIONS') {
    _cors(incoming);
    incoming.response.statusCode = HttpStatus.noContent;
    await incoming.response.close();
    return;
  }

  final target = upstream.replace(
    path: _joinPath(upstream.path, incoming.uri.path),
    query: incoming.uri.hasQuery ? incoming.uri.query : null,
  );

  final outgoing = await client.openUrl(incoming.method, target);
  outgoing.followRedirects = false;
  incoming.headers.forEach((name, values) {
    if (_hopByHop(name)) return;
    for (final value in values) {
      outgoing.headers.add(name, value);
    }
  });
  outgoing.headers.set(
    HttpHeaders.hostHeader,
    upstream.hasPort ? '${upstream.host}:${upstream.port}' : upstream.host,
  );

  await outgoing.addStream(incoming);
  final upstreamResponse = await outgoing.close();

  incoming.response.statusCode = upstreamResponse.statusCode;
  upstreamResponse.headers.forEach((name, values) {
    final lower = name.toLowerCase();
    if (_hopByHop(lower) ||
        lower.startsWith('access-control-') ||
        lower.startsWith('cross-origin-')) {
      return;
    }
    for (final value in values) {
      incoming.response.headers.add(name, value);
    }
  });
  _cors(incoming);
  await incoming.response.addStream(upstreamResponse);
  await incoming.response.close();
}

void _cors(HttpRequest request) {
  final origin = request.headers.value('origin');
  final headers = request.response.headers;
  if (origin == null || origin.isEmpty) {
    headers.set('access-control-allow-origin', '*');
  } else {
    headers.set('access-control-allow-origin', origin);
    headers.set('Access-Control-Allow-Credentials', 'true');
  }
  headers.set(
    'Access-Control-Allow-Methods',
    'GET,POST,PUT,PATCH,DELETE,OPTIONS',
  );
  headers.set(
    'Access-Control-Allow-Headers',
    request.headers.value('access-control-request-headers') ??
        'Content-Type,Authorization,Accept,X-Request-Id,X-Client-Platform,X-Client-App,X-Device-Model',
  );
  headers.set('Access-Control-Allow-Private-Network', 'true');
  headers.set('cross-origin-resource-policy', 'cross-origin');
  headers.set(
    'Access-Control-Expose-Headers',
    'Content-Disposition,X-Request-Id,Retry-After',
  );
  headers.set('Access-Control-Max-Age', '600');
  headers.set('Vary', 'Origin');
}

String _joinPath(String basePath, String requestPath) {
  final request = requestPath.startsWith('/') ? requestPath : '/$requestPath';
  if (basePath.isEmpty || basePath == '/') return request;
  final base = basePath.endsWith('/')
      ? basePath.substring(0, basePath.length - 1)
      : basePath;
  return '$base$request';
}

bool _hopByHop(String name) {
  switch (name.toLowerCase()) {
    case 'connection':
    case 'keep-alive':
    case 'proxy-authenticate':
    case 'proxy-authorization':
    case 'te':
    case 'trailer':
    case 'transfer-encoding':
    case 'upgrade':
    case 'host':
    case 'content-length':
      return true;
    default:
      return false;
  }
}

String? _arg(List<String> args, String name) {
  final index = args.indexOf(name);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
