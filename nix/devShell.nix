pkgs:
let
  androidPackages = import ./android.nix pkgs;
  rustupCompat = import ./rustup-compat.nix pkgs;
  nativePkgConfig = import ./native-pkg-config.nix pkgs;
  androidSdkRoot = "${androidPackages.androidsdk}/libexec/android-sdk";
in
pkgs.mkShell rec {
  buildInputs = with pkgs; [
    gtk3
    libx11
    libxi
    libsecret
  ];

  packages = with pkgs; [
    (nativePkgConfig buildInputs)

    flutter
    flutter.dart

    rustToolchain
    cargo-binstall
    rustupCompat

    temurin-bin-21
    androidPackages.androidsdk

    just
    just-lsp
    nixfmt
  ];

  env = with pkgs; {
    LD_LIBRARY_PATH = lib.makeLibraryPath buildInputs;
    FLUTTER_ROOT = "${flutter}";
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
    JAVA_HOME = "${temurin-bin-21}";
    ANDROID_HOME = androidSdkRoot;
    ANDROID_SDK_ROOT = androidSdkRoot;
    ANDROID_NDK_HOME = "${androidSdkRoot}/ndk/28.2.13676358";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/36.0.0/aapt2";
  };

  shellHook = ''
    export CARGO_HOME="$PWD/.cargo"
    export ANDROID_AVD_HOME="$HOME/.android/avd"
    export PATH="$CARGO_HOME/bin:$PWD/target/debug:$PATH"
    export XDG_DATA_DIRS="${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
    mkdir -p "$ANDROID_AVD_HOME"
  '';
}
