# Wait for https://dart.googlesource.com/native/+/18386375888e370851e2f8851a2d7ca84273d6f5
pkgs: buildInputs:
pkgs.symlinkJoin {
  name = "pkg-config-native";
  paths = [ pkgs.pkg-config ];
  nativeBuildInputs = with pkgs; [
    pkg-config
    makeWrapper
  ];
  inherit buildInputs;
  postBuild = ''
    wrapProgram "$out/bin/pkg-config" \
      --prefix PKG_CONFIG_PATH : "$PKG_CONFIG_PATH"
  '';
}
