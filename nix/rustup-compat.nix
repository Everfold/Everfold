pkgs:
# Only the rustup calls used by native_toolchain_rust are supported.
# Rust components and targets remain managed exclusively by Nix.
pkgs.writeShellApplication {
  name = "rustup";
  text = ''
    version=${pkgs.lib.escapeShellArg pkgs.rustToolchain.version}

    if [[ $# -eq 2 && $1 == show && $2 == active-toolchain ]]; then
      printf '%s (Nix toolchain)\n' "$version"
      exit 0
    fi

    if [[ $# -ge 3 && $1 == run ]]; then
      if [[ $2 != "$version" ]]; then
        printf 'Nix provides Rust %s, but rustup run requested %s. Update rust-toolchain.toml and reload the Nix shell.\n' "$version" "$2" >&2
        exit 64
      fi
      shift 2
      tool=$1
      shift
      case "$tool" in
        cargo|rustc)
          export RUSTC="${pkgs.rustToolchain}/bin/rustc"
          exec "${pkgs.rustToolchain}/bin/$tool" "$@"
          ;;
      esac
    fi

    printf 'This is the Nix rustup adapter, not a toolchain installer. Supported: show active-toolchain; run %s {cargo|rustc} ...\n' "$version" >&2
    exit 64
  '';
}
