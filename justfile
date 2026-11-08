set positional-arguments

default:
  @just --list

install-dev:
  cargo binstall cargo-update cargo-expand prek flutter_rust_bridge_codegen -y

build +args:
  flutter build "$@"

run *args:
  flutter run "$@"

generate:
  flutter_rust_bridge_codegen generate

lint:
  prek run --all-files

test:
  cargo test
  flutter test

fmt:
  dart format lib hook test
  cargo fmt --all
  nixfmt flake.nix nix/*.nix

android-emulator:
  emulator -avd everfold -gpu host

update:
  flutter pub upgrade
  cargo update
  cargo install-update -a
  prek autoupdate
  nix flake update
  npx skills update
