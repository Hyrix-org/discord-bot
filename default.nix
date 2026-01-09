{
  rustPlatform,
  rust-bin,
}:
rustPlatform.buildRustPackage {
  pname = "teaclient-discord-bot";
  version = (fromTOML (builtins.readFile ./Cargo.toml)).package.version;

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    rust-bin.stable.latest.default
  ];
}
