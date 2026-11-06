set positional-arguments
default:
    @just --list

install-dev:
    cargo binstall cargo-update prek wasm-pack flutter_rust_bridge_codegen -y --force

update:
    cargo install-update -a
    prek autoupdate
    nix flake update
    npx skills update
