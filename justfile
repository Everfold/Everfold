set positional-arguments

default:
  @just --list

install-dev:
  cargo binstall cargo-update prek flutter_rust_bridge_codegen -y

run *args:
  flutter run "$@"

android-emulator:
  emulator -avd everfold-api-36-x86_64 -gpu host

fmt:
  dart format lib hook integration_test test_driver
  cargo fmt --all
  nixfmt flake.nix nix/*.nix

lint:
  prek run --all-files

generate *args:
  flutter_rust_bridge_codegen generate "$@"

update:
  cargo install-update -a
  prek autoupdate
  nix flake update
  npx skills update
