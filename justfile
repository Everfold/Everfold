set positional-arguments
default:
  @just --list

install-dev:
  cargo binstall cargo-update prek wasm-pack flutter_rust_bridge_codegen -y --force

run:
  flutter run

android-emulator:
  emulator -avd everfold-api-36-x86_64 -gpu host

update:
  cargo install-update -a
  prek autoupdate
  nix flake update
  npx skills update
