import '../../../domain/common/app_failure.dart';
import '../../../l10n/app_localizations.dart';

/// 将安全的失败分类映射为展示文案, 不展示原始异常文本
String failureMessage(Object error, AppLocalizations strings) {
  final kind = error is AppFailure ? error.kind : FailureKind.unexpected;
  return switch (kind) {
    FailureKind.configuration => strings.errorConfiguration,
    FailureKind.network => strings.errorNetwork,
    FailureKind.timeout => strings.errorTimeout,
    FailureKind.cancelled => strings.errorCancelled,
    FailureKind.unauthorized => strings.errorUnauthorized,
    FailureKind.forbidden => strings.errorForbidden,
    FailureKind.notFound => strings.errorPageNotFound,
    FailureKind.conflict => strings.errorConflict,
    FailureKind.validation => strings.errorValidation,
    FailureKind.server => strings.errorServer,
    FailureKind.invalidData => strings.errorInvalidData,
    FailureKind.storage => strings.errorStorage,
    FailureKind.unexpected => strings.errorUnexpected,
  };
}
