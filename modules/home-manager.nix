{ config, lib, pkgs, ... }:
let
  cfg = config.programs.headroom;
  wrapperLib = import ./lib.nix { inherit lib; };
in
{
  options.programs.headroom = wrapperLib.mkOptions { inherit pkgs cfg; };

  config = lib.mkIf cfg.enable {
    home.packages = wrapperLib.mkPackages { inherit pkgs cfg; };
  };
}
