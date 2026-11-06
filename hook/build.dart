import 'package:flutter_rust_bridge_hooks/flutter_rust_bridge_hooks.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    output.dependencies.addAll([
      input.packageRoot.resolve('Cargo.toml'),
      input.packageRoot.resolve('Cargo.lock'),
      input.packageRoot.resolve('rust-toolchain.toml'),
    ]);
    await const FlutterRustBridgeNativeAssetsBuilder(cratePath: '.')
        .run(input: input, output: output);
  });
}
