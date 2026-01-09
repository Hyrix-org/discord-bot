let
  eveeifyeve-nixos = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGFy81uW8QQKva3vDeKJo0rAoUmzrsTON28zWyWYAh1v eveeifyeve@nixos";

  keys = import (
    builtins.fetchGit {
      url = "git@github.com:digitalbrewstudios/infa.git";
      ref = "Stable";
    }
    + "/hosts/ssh-keys.nix"
  );

  secrets = {
    Discord_Token = [ eveeifyeve-nixos ];
  };
in
builtins.listToAttrs (
  map (secretName: {
    name = "${secretName}.age";
    value.publicKeys = secrets."${secretName}" ++ keys.teaclient-developers;
  }) (builtins.attrNames secrets)
)
