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

# Build
just build

# Run on specify platform
just run -d linux

# Regenerate Rust bindings
just generate

# Lint
just lint

# Test
just test

# Format
just fmt

# Update
just update
```

#### Android

Set up Android development: [Setup](https://docs.flutter.dev/platform-integration/android/setup)

```bash
# Env check
flutter doctor

# Create AVD
avdmanager create avd --name everfold --device pixel_9_pro --package 'system-images;android-36;google_apis;x86_64'

# Run in Android Emulator
just android-emulator
flutter devices
just run -d emulator

# Build APK
just build apk --debug --target-platform android-arm64
```
