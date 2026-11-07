import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';

enum _ConnectionStatus { idle, connecting, succeeded }

enum _CertificateSource { file, qr }

// 连接界面尚未接入后端, 不访问网络, 文件, 摄像头或凭据存储
class ConnectionForm extends StatefulWidget {
  const ConnectionForm({
    super.key,
    required this.saving,
    required this.onConnectionStarted,
    required this.onNext,
  });

  final bool saving;
  final VoidCallback onConnectionStarted;
  final VoidCallback onNext;

  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends State<ConnectionForm> {
  final _ip = TextEditingController();
  final _port = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _certificates = <String, _CertificateSource>{};
  String _provider = 'lan';
  String _verification = 'none';
  _ConnectionStatus _status = _ConnectionStatus.idle;
  Timer? _timer;

  bool get _locked => widget.saving || _status != _ConnectionStatus.idle;
  bool get _actionBusy =>
      widget.saving || _status == _ConnectionStatus.connecting;

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

  void _connect() {
    if (_actionBusy) return;
    if (_status == _ConnectionStatus.succeeded) {
      widget.onNext();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _status = _ConnectionStatus.connecting);
    widget.onConnectionStarted();
    // 后端接入前固定等待 1 秒, 不做地址校验, 认证或 TLS 握手
    _timer = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _status = _ConnectionStatus.succeeded);
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

  Widget _certificate(String slot, String label) {
    final strings = AppLocalizations.of(context)!;
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
                label: Text(strings.chooseLocalFile),
              ),
              OutlinedButton.icon(
                key: ValueKey('certificate-$slot-qr'),
                onPressed: _locked ? null : () => choose(_CertificateSource.qr),
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(strings.scanQrCode),
              ),
            ],
          ),
          if (selected != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected == _CertificateSource.file
                        ? strings.certificateFileSelected
                        : strings.certificateQrSelected,
                    key: ValueKey('certificate-$slot-selection'),
                  ),
                ),
                IconButton(
                  key: ValueKey('certificate-$slot-clear'),
                  tooltip: strings.clearCertificate,
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
    final strings = AppLocalizations.of(context)!;
    final cloud = _provider == 'testCloud';
    final selfHosted = _provider == 'selfHosted';
    final credentials = cloud || (selfHosted && _verification == 'credentials');
    final connecting = _status == _ConnectionStatus.connecting;
    final succeeded = _status == _ConnectionStatus.succeeded;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownMenu<String>(
          key: const ValueKey('login-provider'),
          initialSelection: _provider,
          expandedInsets: EdgeInsets.zero,
          enabled: !_locked,
          label: Text(strings.identityProvider),
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 'lan', label: strings.lanProvider),
            DropdownMenuEntry(
              value: 'selfHosted',
              label: strings.selfHostedProvider,
            ),
            DropdownMenuEntry(
              value: 'testCloud',
              label: strings.testCloudProvider,
            ),
          ],
          onSelected: _selectProvider,
        ),
        if (selfHosted) ...[
          _input('ip', strings.serverIp, _ip),
          _input(
            'port',
            strings.serverPort,
            _port,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          DropdownMenu<String>(
            key: const ValueKey('login-verification'),
            initialSelection: _verification,
            expandedInsets: EdgeInsets.zero,
            enabled: !_locked,
            label: Text(strings.verificationLabel),
            dropdownMenuEntries: [
              DropdownMenuEntry(value: 'none', label: strings.verificationNone),
              DropdownMenuEntry(
                value: 'credentials',
                label: strings.verificationCredentials,
              ),
              DropdownMenuEntry(
                value: 'serverCertificate',
                label: strings.serverCertificate,
              ),
              const DropdownMenuEntry(value: 'mtls', label: 'mTLS'),
            ],
            onSelected: _selectVerification,
          ),
          if (_verification == 'serverCertificate')
            _certificate('server', strings.serverCertificate),
          if (_verification == 'mtls') ...[
            _certificate('ca', 'CA'),
            _certificate('publicKey', strings.publicKey),
            _certificate('privateKey', strings.privateKey),
          ],
        ],
        if (credentials) ...[
          _input('username', strings.usernameLabel, _username),
          _input('password', strings.passwordLabel, _password, secret: true),
        ],
        if (connecting || succeeded) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              connecting
                  ? (cloud ? strings.signingInStatus : strings.connectingStatus)
                  : (cloud
                        ? strings.signInSucceeded
                        : strings.connectionSucceeded),
              key: const ValueKey('connection-connection-status'),
            ),
          ),
        ],
        if (connecting) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const ValueKey('connection-connect'),
            onPressed: _actionBusy ? null : _connect,
            icon: Icon(
              succeeded
                  ? Icons.arrow_forward
                  : (cloud ? Icons.login : Icons.link),
            ),
            label: Text(
              succeeded
                  ? strings.nextStep
                  : (cloud ? strings.loginAction : strings.connectAction),
            ),
          ),
        ),
      ],
    );
  }
}
