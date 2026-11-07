import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 不访问真实网络的传输适配器
final class StubHttpAdapter implements HttpClientAdapter {
  StubHttpAdapter(this.respond);

  final Future<ResponseBody> Function(RequestOptions options) respond;
  final requests = <RequestOptions>[];
  bool closed = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return respond(options);
  }

  @override
  void close({bool force = false}) {
    closed = true;
  }
}
