pkgs:
let
  androidPackages = import ./android.nix pkgs;
  androidSdkRoot = "${androidPackages.androidsdk}/libexec/android-sdk";
  rustupCompat = import ./rustup-compat.nix pkgs;
in
rec {
  packages = with pkgs; [
    pkg-config
    libsecret

    flutter
    dart

    rustToolchain
    rustupCompat
    cargo-binstall

    jdk17
    androidPackages.androidsdk

    just
    just-lsp
    nixfmt
  ];

  env = with pkgs; rec {
    LD_LIBRARY_PATH = lib.makeLibraryPath packages;
    FLUTTER_ROOT = "${flutter}";
    RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
    JAVA_HOME = "${jdk17}";
    ANDROID_HOME = androidSdkRoot;
    ANDROID_SDK_ROOT = androidSdkRoot;
    ANDROID_NDK_HOME = "${androidSdkRoot}/ndk/28.2.13676358";
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdkRoot}/build-tools/36.0.0/aapt2";
  };

  shellHook = ''
    export ANDROID_AVD_HOME="$HOME/.android/avd"
    mkdir -p "$ANDROID_AVD_HOME"
    export CARGO_HOME="$PWD/.cargo"
    export PATH="$CARGO_HOME/bin:$PWD/target/debug:$PATH"
  '';
}
