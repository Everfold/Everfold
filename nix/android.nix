pkgs:
pkgs.androidenv.composeAndroidPackages {
  platformVersions = [
    "35"
    "36"
  ];
  buildToolsVersions = [ "36.0.0" ];
  cmdLineToolsVersion = "19.0";
  platformToolsVersion = "37.0.1";
  includeNDK = true;
  ndkVersions = [ "28.2.13676358" ];
  includeCmake = true;
  cmakeVersions = [ "3.22.1" ];
  includeEmulator = true;
  emulatorVersion = "37.2.13";
  includeSystemImages = true;
  systemImageTypes = [ "google_apis" ];
  abiVersions = [ "x86_64" ];
  useGoogleAPIs = false;
}
