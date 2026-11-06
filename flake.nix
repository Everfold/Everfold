{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flakelight.url = "github:nix-community/flakelight";
  };

  outputs =
    { flakelight, ... }@inputs:
    flakelight ./. {
      inherit inputs;

      withOverlays = [
        inputs.rust-overlay.overlays.default

        (final: prev: {
          rustToolchain =
            let
              rust = prev.rust-bin;
            in
            if builtins.pathExists ./rust-toolchain.toml then
              rust.fromRustupToolchainFile ./rust-toolchain.toml

            else if builtins.pathExists ./rust-toolchain then
              rust.fromRustupToolchainFile ./rust-toolchain

            else
              rust.stable."1.99.1".default.override {
                extensions = [
                  "rust-src"
                  "rustfmt"
                  "rust-analyzer"
                  "clippy"
                  "cargo"
                ];

                targets = [
                  "aarch64-apple-darwin"
                  "aarch64-apple-ios"
                  "aarch64-apple-ios-sim"
                  "aarch64-linux-android"
                  "aarch64-pc-windows-msvc"
                  "aarch64-unknown-linux-gnu"

                  "armv7-linux-androideabi"

                  "wasm32-unknown-unknown"

                  "x86_64-apple-darwin"
                  "x86_64-apple-ios"
                  "x86_64-linux-android"
                  "x86_64-pc-windows-msvc"
                  "x86_64-unknown-linux-gnu"
                ];
              };
        })
      ];

      devShell = pkgs: rec {
        packages = with pkgs; [
          pkg-config

          rustToolchain
          cargo-binstall

          flutter
          dart

          just
          just-lsp
        ];

        env = with pkgs; rec {
          LD_LIBRARY_PATH = lib.makeLibraryPath packages;
          FLUTTER_ROOT = "${flutter}";
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/library";
        };

        shellHook = ''
          export CARGO_HOME="$PWD/.cargo"
          export PATH="$CARGO_HOME/bin:$PWD/target/debug:$PATH"
        '';
      };
    };
}
