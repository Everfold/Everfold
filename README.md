# Everfold

## Build

### Development Environment

#### Linux

Requirement:

- Rust >= 1.99.1
- Flutter

```bash
apt install rustup \
  cargo-binstall \
  just

sudo snap install flutter --classic

flutter doctor
```

#### Nix

```bash
# Nix Shell
nix develop

# OR Direnv
apt install -y direnv
echo 'use flake' > .envrc
direnv allow
```

### Project

```bash
# Dev Tools
just install-dev

# Update
just update
```
