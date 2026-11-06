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

# Run
just run

# Lint
just lint

# Format
just fmt

# Regenerate bindings after changing the Rust API
just generate

# Update
just update
```

#### Android

Set up Android development: [Setup](https://docs.flutter.dev/platform-integration/android/setup)

```bash
# Env check
flutter doctor

# Create AVD
avdmanager create avd --name everfold-api-36-x86_64 --package 'system-images;android-36;google_apis;x86_64' --device pixel_7

# Run in Android Emulator
just android-emulator
flutter devices
just run
```
