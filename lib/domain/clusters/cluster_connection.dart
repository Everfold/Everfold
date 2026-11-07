enum ClusterService { lan, selfHosted, testCloud }

enum ClusterVerification { none, credentials, serverCertificate, mtls }

enum ClusterStatus { connected, disconnected }

// 仅保留非敏感配置, 不包含账号, 密码, 证书内容或私钥
final class ClusterConfiguration {
  const ClusterConfiguration({
    this.service = ClusterService.lan,
    this.ip = '',
    this.port = '',
    this.verification = ClusterVerification.none,
  });

  final ClusterService service;
  final String ip;
  final String port;
  final ClusterVerification verification;
}

final class ClusterConnection {
  const ClusterConnection({
    required this.id,
    required this.name,
    required this.configuration,
    this.status = ClusterStatus.connected,
  });

  final String id;
  final String name;
  final ClusterConfiguration configuration;
  final ClusterStatus status;

  ClusterConnection copyWith({
    String? name,
    ClusterConfiguration? configuration,
    ClusterStatus? status,
  }) => ClusterConnection(
    id: id,
    name: name ?? this.name,
    configuration: configuration ?? this.configuration,
    status: status ?? this.status,
  );
}
