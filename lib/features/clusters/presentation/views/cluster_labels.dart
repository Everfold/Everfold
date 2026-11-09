import '../../domain/cluster_connection.dart';
import '../../../../l10n/app_localizations.dart';

String clusterServiceLabel(AppLocalizations strings, ClusterService service) =>
    switch (service) {
      ClusterService.lan => strings.clusterLanProvider,
      ClusterService.selfHosted => strings.clusterSelfHostedProvider,
      ClusterService.testCloud => strings.clusterTestCloudProvider,
    };

String clusterVerificationLabel(
  AppLocalizations strings,
  ClusterVerification verification,
) => switch (verification) {
  ClusterVerification.none => strings.clusterVerificationNone,
  ClusterVerification.credentials => strings.clusterVerificationCredentials,
  ClusterVerification.serverCertificate => strings.clusterServerCertificate,
  ClusterVerification.mtls => 'mTLS',
};
