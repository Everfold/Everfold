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

      nixpkgs.config = {
        allowUnfree = true;
        android_sdk.accept_license = true;
      };

      withOverlays = [
        inputs.rust-overlay.overlays.default
        (import ./nix/rust-overlay.nix)

        # https://github.com/NixOS/nixpkgs/pull/567033
        (
          final: prev:
          let
            data = builtins.fromJSON (
              builtins.readFile (
                builtins.fetchurl {
                  url = "https://raw.githubusercontent.com/NixOS/nixpkgs/b261929c914668774bb7ae4f6d96bd0ca8f99630/pkgs/development/compilers/flutter/versions/3_47/data.json";
                  sha256 = "sha256-dZxfpdlB+8xO260Et+DrQBHKZY/aLihkhS4qwEZzHT4=";
                }
              )
            );
          in
          {
            flutter = prev.flutterPackages.wrapFlutter (
              prev.flutterPackages.mkFlutter (data // { inherit (prev.flutterPackages.v3_47.unwrapped) patches; })
            );
          }
        )
      ];
    };
}
