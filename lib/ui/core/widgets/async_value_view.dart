import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../l10n/app_localizations.dart';
import '../error/failure_message.dart';

/// 使用默认 Material 控件展示异步加载, 失败与数据内容
///
/// 只在调用方明确提供 onRetry 时显示重试操作, 不自动重放业务请求
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T value) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return value.when(
      skipLoadingOnRefresh: false,
      skipError: false,
      data: data,
      loading: () => Center(
        child: CircularProgressIndicator(semanticsLabel: strings.loading),
      ),
      error: (error, stackTrace) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline),
              const SizedBox(height: 16),
              Text(failureMessage(error, strings), textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onRetry, child: Text(strings.retry)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
