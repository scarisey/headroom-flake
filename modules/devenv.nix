{ config, lib, pkgs, ... }:
let
  cfg = config.headroom;
  wrapperLib = import ./lib.nix { inherit lib; };
in
{
  options.headroom = wrapperLib.mkOptions { inherit pkgs cfg; };

  config = lib.mkIf cfg.enable {
    packages = wrapperLib.mkPackages { inherit pkgs cfg; };
  };
}
