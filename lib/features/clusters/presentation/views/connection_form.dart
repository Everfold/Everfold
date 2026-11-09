import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../domain/cluster_connection.dart';
import '../../../../l10n/app_localizations.dart';

enum _ConnectionStatus { idle, connecting, succeeded }

enum _CertificateSource { file, qr }

/// 组合连接字段和主操作, 支持引导内联布局与集群弹窗布局
///
/// 尚未接入后端, 不访问网络, 文件, 摄像头或凭据存储
class ConnectionForm extends StatefulWidget {
  const ConnectionForm({
    super.key,
    required this.saving,
    required this.onNext,
    this.onConnectionStarted,
    this.advanceOnSuccess = false,
    this.layoutBuilder,
    this.initialConfiguration = const ClusterConfiguration(),
  });

  final bool saving;
  final VoidCallback? onConnectionStarted;

  /// 仅返回非敏感配置, 不携带账号, 密码或证书内容
  final ValueChanged<ClusterConfiguration> onNext;

  /// 为 `true` 时连接成功后自动提交, 否则等待用户点击下一步
  final bool advanceOnSuccess;

  /// 调用方可安排字段与主按钮的位置, 锁定状态仍由表单统一提供
  final Widget Function(Widget fields, Widget action, bool locked)?
  layoutBuilder;
  final ClusterConfiguration initialConfiguration;

  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _ip = TextEditingController();
  final _port = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _certificates = <String, _CertificateSource>{};
  late String _provider;
  late String _verification;
  _ConnectionStatus _status = _ConnectionStatus.idle;
  Timer? _timer;

  // 字段锁与主按钮锁分开: 引导成功后字段冻结, 但下一步仍需可点击
  bool get _locked => widget.saving || _status != _ConnectionStatus.idle;
  bool get _actionBusy =>
      widget.saving ||
      _status == _ConnectionStatus.connecting ||
      (widget.advanceOnSuccess && _status == _ConnectionStatus.succeeded);

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfiguration;
    _provider = config.service.name;
    _verification = config.verification.name;
    _ip.text = config.ip;
    _port.text = config.port;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ip.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _selectProvider(String? value) {
    if (_locked || value == null || value == _provider) return;
    setState(() {
      _provider = value;
      _verification = 'none';
      _status = _ConnectionStatus.idle;
      _ip.clear();
      _port.clear();
      _username.clear();
      _password.clear();
      _certificates.clear();
    });
  }

  void _selectVerification(String? value) {
    if (_locked || value == null || value == _verification) return;
    setState(() {
      _verification = value;
      _status = _ConnectionStatus.idle;
      _username.clear();
      _password.clear();
      _certificates.clear();
    });
  }

  void _advance() {
    final selfHosted = _provider == 'selfHosted';
    widget.onNext(
      ClusterConfiguration(
        service: ClusterService.values.byName(_provider),
        ip: selfHosted ? _ip.text.trim() : '',
        port: selfHosted ? _port.text.trim() : '',
        verification: selfHosted
            ? ClusterVerification.values.byName(_verification)
            : ClusterVerification.none,
      ),
    );
  }

  void _connect() {
    if (_actionBusy) return;
    if (_status == _ConnectionStatus.succeeded) {
      _advance();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _status = _ConnectionStatus.connecting);
    widget.onConnectionStarted?.call();
    // 后端接入前固定等待 1 秒, 不做地址校验, 认证或 TLS 握手
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _status = _ConnectionStatus.succeeded);
      if (widget.advanceOnSuccess) _advance();
    });
  }

  Widget _input(
    String name,
    String label,
    TextEditingController controller, {
    bool secret = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: TextField(
        key: ValueKey('connection-$name'),
        controller: controller,
        enabled: !_locked,
        obscureText: secret,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // 这里只显示来源选择状态, 不读取文件或启动摄像头
  Widget _certificate(String slot, String label) {
    final strings = AppLocalizations.of(context);
    final selected = _certificates[slot];
    void choose(_CertificateSource source) {
      setState(() {
        _certificates[slot] = source;
        _status = _ConnectionStatus.idle;
      });
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: ValueKey('certificate-$slot-file'),
                onPressed: _locked
                    ? null
                    : () => choose(_CertificateSource.file),
                icon: const Icon(Icons.file_open_outlined),
                label: Text(strings.clusterChooseLocalFile),
              ),
              OutlinedButton.icon(
                key: ValueKey('certificate-$slot-qr'),
                onPressed: _locked ? null : () => choose(_CertificateSource.qr),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(strings.clusterScanQrCode),
              ),
            ],
          ),
          if (selected != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected == _CertificateSource.file
                        ? strings.clusterCertificateFileSelected
                        : strings.clusterCertificateQrSelected,
                    key: ValueKey('certificate-$slot-selection'),
                  ),
                ),
                IconButton(
                  key: ValueKey('certificate-$slot-clear'),
                  tooltip: strings.clusterClearCertificate,
                  onPressed: _locked
                      ? null
                      : () => setState(() {
                          _certificates.remove(slot);
                          _status = _ConnectionStatus.idle;
                        }),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final fields = _buildFields(strings);
    final action = _buildAction(strings);

    // 集群弹窗接管布局, 将主按钮与取消放在 actions; 引导使用下方默认排列
    final layoutBuilder = widget.layoutBuilder;
    if (layoutBuilder != null) return layoutBuilder(fields, action, _locked);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fields,
        const SizedBox(height: 24),
        Align(alignment: Alignment.centerRight, child: action),
      ],
    );
  }

  // 字段区根据服务类型和验证方式展开, 控制器与证书来源状态仍由本 State 持有
  Widget _buildFields(AppLocalizations strings) {
    final cloud = _provider == 'testCloud';
    final selfHosted = _provider == 'selfHosted';
    final credentials = cloud || (selfHosted && _verification == 'credentials');
    final connecting = _status == _ConnectionStatus.connecting;
    final succeeded = _status == _ConnectionStatus.succeeded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownMenu<String>(
          key: const ValueKey('login-provider'),
          initialSelection: _provider,
          expandedInsets: EdgeInsets.zero,
          enabled: !_locked,
          label: _DropdownMenuBackHandler(
            child: Text(strings.clusterIdentityProvider),
          ),
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 'lan', label: strings.clusterLanProvider),
            DropdownMenuEntry(
              value: 'selfHosted',
              label: strings.clusterSelfHostedProvider,
            ),
            DropdownMenuEntry(
              value: 'testCloud',
              label: strings.clusterTestCloudProvider,
            ),
          ],
          onSelected: _selectProvider,
        ),
        if (selfHosted) ...[
          _input('ip', strings.clusterServerIp, _ip),
          _input(
            'port',
            strings.clusterServerPort,
            _port,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            key: const ValueKey('login-verification'),
            initialSelection: _verification,
            expandedInsets: EdgeInsets.zero,
            enabled: !_locked,
            label: _DropdownMenuBackHandler(
              child: Text(strings.clusterVerificationLabel),
            ),
            dropdownMenuEntries: [
              DropdownMenuEntry(
                value: 'none',
                label: strings.clusterVerificationNone,
              ),
              DropdownMenuEntry(
                value: 'credentials',
                label: strings.clusterVerificationCredentials,
              ),
              DropdownMenuEntry(
                value: 'serverCertificate',
                label: strings.clusterServerCertificate,
              ),
              const DropdownMenuEntry(value: 'mtls', label: 'mTLS'),
            ],
            onSelected: _selectVerification,
          ),
          if (_verification == 'serverCertificate')
            _certificate('server', strings.clusterServerCertificate),
          if (_verification == 'mtls') ...[
            _certificate('ca', 'CA'),
            _certificate('publicKey', strings.clusterPublicKey),
            _certificate('privateKey', strings.clusterPrivateKey),
          ],
        ],
        if (credentials) ...[
          _input('username', strings.clusterUsernameLabel, _username),
          _input(
            'password',
            strings.clusterPasswordLabel,
            _password,
            secret: true,
          ),
        ],
        if (connecting || succeeded) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              connecting
                  ? (cloud
                        ? strings.clusterSigningInStatus
                        : strings.clusterConnectingStatus)
                  : (cloud
                        ? strings.clusterSignInSucceeded
                        : strings.clusterConnectionSucceeded),
              key: const ValueKey('connection-connection-status'),
            ),
          ),
        ],
        if (connecting) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  // 主操作区独立于字段排列, 供引导页面和连接弹窗使用同一套按钮状态
  Widget _buildAction(AppLocalizations strings) {
    final cloud = _provider == 'testCloud';
    final awaitingNext =
        _status == _ConnectionStatus.succeeded && !widget.advanceOnSuccess;
    return FilledButton.icon(
      key: const ValueKey('connection-connect'),
      onPressed: _actionBusy ? null : _connect,
      icon: Icon(
        awaitingNext ? Icons.arrow_forward : (cloud ? Icons.login : Icons.link),
      ),
      label: Text(
        awaitingNext
            ? strings.commonNextStep
            : (cloud
                  ? strings.clusterLoginAction
                  : strings.clusterConnectAction),
      ),
    );
  }
}

// DropdownMenu 没有开关回调; label 位于内部 MenuAnchor 下方, 可观察菜单状态。
// 使用本地历史让返回先关闭选项, 避免同时触发弹窗退出或引导的阶段返回。
class _DropdownMenuBackHandler extends StatefulWidget {
  const _DropdownMenuBackHandler({required this.child});

  final Widget child;

  @override
  State<_DropdownMenuBackHandler> createState() =>
      _DropdownMenuBackHandlerState();
}

class _DropdownMenuBackHandlerState extends State<_DropdownMenuBackHandler> {
  LocalHistoryEntry? _history;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final open = MenuController.maybeIsOpenOf(context) ?? false;
    if (!open) {
      _removeHistory();
      return;
    }
    if (_history != null) return;
    final controller = MenuController.maybeOf(context)!;
    final route = ModalRoute.of(context);
    // 注册历史会通知路由重建, 必须等当前菜单的构建完成。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _history != null ||
          !controller.isOpen ||
          route == null ||
          !route.isCurrent) {
        return;
      }
      final entry = LocalHistoryEntry(
        impliesAppBarDismissal: false,
        onRemove: () {
          if (_history == null) return;
          _history = null;
          controller.close();
        },
      );
      _history = entry;
      route.addLocalHistoryEntry(entry);
    });
  }

  void _removeHistory() {
    final entry = _history;
    _history = null;
    entry?.remove();
  }

  @override
  void dispose() {
    _removeHistory();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
