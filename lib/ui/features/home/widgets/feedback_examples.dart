import 'package:material_ui/material_ui.dart';

import '../../../../l10n/app_localizations.dart';
import 'showcase_section.dart';

/// 展示确定进度, 避免静态示例产生持续运行的加载动画
class FeedbackExamples extends StatelessWidget {
  const FeedbackExamples({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context)!;
    return ShowcaseSection(
      title: strings.feedbackTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(strings.linearProgress),
          const SizedBox(height: 16),
          const LinearProgressIndicator(value: 0.6),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircularProgressIndicator(
                value: 0.6,
                semanticsLabel: strings.circularProgress,
              ),
              Text(strings.circularProgress),
              Tooltip(
                message: strings.tooltipMessage,
                child: IconButton(
                  tooltip: null,
                  onPressed: null,
                  icon: const Icon(Icons.info_outline),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
