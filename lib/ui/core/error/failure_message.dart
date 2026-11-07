import '../../../domain/common/app_failure.dart';
import '../../../l10n/app_localizations.dart';

/// 将安全的失败分类映射为展示文案, 不展示原始异常文本
String failureMessage(Object error, AppLocalizations strings) {
  final kind = error is AppFailure ? error.kind : FailureKind.unexpected;
  return switch (kind) {
    FailureKind.configuration => strings.configurationFailure,
    FailureKind.network => strings.networkFailure,
    FailureKind.timeout => strings.timeoutFailure,
    FailureKind.cancelled => strings.cancelledFailure,
    FailureKind.unauthorized => strings.unauthorizedFailure,
    FailureKind.forbidden => strings.forbiddenFailure,
    FailureKind.notFound => strings.pageNotFound,
    FailureKind.conflict => strings.conflictFailure,
    FailureKind.validation => strings.validationFailure,
    FailureKind.server => strings.serverFailure,
    FailureKind.invalidData => strings.invalidDataFailure,
    FailureKind.storage => strings.storageFailure,
    FailureKind.unexpected => strings.unexpectedFailure,
  };
}
