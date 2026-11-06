import 'package:material_ui/material_ui.dart';

import '../../domain/models.dart';
import '../core/adaptive.dart';
import '../core/app_scope.dart';

class ConnectionEditor extends StatefulWidget {
  const ConnectionEditor({
    super.key,
    this.profile,
    required this.onSaved,
    this.submitLabel = '保存连接',
  });
  final ConnectionProfile? profile;
  final VoidCallback onSaved;
  final String submitLabel;

  @override
  State<ConnectionEditor> createState() => _ConnectionEditorState();
}

class _ConnectionEditorState extends State<ConnectionEditor> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _credential;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile?.name ?? '默认连接');
    _address = TextEditingController(
      text: widget.profile?.endpoint.toString() ?? '',
    );
    _credential = TextEditingController(text: widget.profile?.credential ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _credential.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('连接名称'),
      const SizedBox(height: 8),
      AppInput(
        key: const ValueKey('connection-name'),
        controller: _name,
        placeholder: '例如：我的连接',
      ),
      const SizedBox(height: 20),
      const Text('服务地址'),
      const SizedBox(height: 8),
      AppInput(
        key: const ValueKey('connection-address'),
        controller: _address,
        placeholder: 'https://your-service.example',
      ),
      const SizedBox(height: 20),
      const Text('访问凭据（可选）'),
      const SizedBox(height: 8),
      AppInput(
        key: const ValueKey('connection-credential'),
        controller: _credential,
        placeholder: '仅在本次运行期间保留',
        secret: true,
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Notice(_error!),
        ),
      const SizedBox(height: 20),
      Align(
        alignment: Alignment.centerLeft,
        child: AppButton(
          label: widget.submitLabel,
          primary: true,
          onPressed: () {
            final error = AppScope.of(context).saveConnection(
              id: widget.profile?.id,
              name: _name.text,
              address: _address.text,
              credential: _credential.text,
            );
            if (error == null) {
              widget.onSaved();
            } else {
              setState(() => _error = error);
            }
          },
        ),
      ),
    ],
  );
}
