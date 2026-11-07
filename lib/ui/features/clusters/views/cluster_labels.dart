import '../../../../domain/clusters/cluster_connection.dart';
import '../../../../l10n/app_localizations.dart';

String clusterServiceLabel(AppLocalizations strings, ClusterService service) =>
    switch (service) {
      ClusterService.lan => strings.lanProvider,
      ClusterService.selfHosted => strings.selfHostedProvider,
      ClusterService.testCloud => strings.testCloudProvider,
    };

String clusterVerificationLabel(
  AppLocalizations strings,
  ClusterVerification verification,
) => switch (verification) {
  ClusterVerification.none => strings.verificationNone,
  ClusterVerification.credentials => strings.verificationCredentials,
  ClusterVerification.serverCertificate => strings.serverCertificate,
  ClusterVerification.mtls => 'mTLS',
};
