{
  pkgs,
  nixosModules,
  homeManagerModules,
  devenvModules,
}:
let
  inherit (pkgs) lib;
  harness = pkgs.writeShellScriptBin "opencode" "echo plain";
  headroom = pkgs.writeShellScriptBin "headroom" ''
    printf '%s\n' "$(command -v opencode)" "$@"
  '';
  packageOption = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
  };
  eval =
    module: optionModule: settings:
    lib.evalModules {
      modules = [
        module
        optionModule
        settings
      ];
      specialArgs = { inherit pkgs; };
    };
  nixos = eval nixosModules.default {
    options.environment.systemPackages = packageOption;
  };
  home = eval homeManagerModules.default {
    options.home.packages = packageOption;
  };
  devenv = eval devenvModules.default {
    options.packages = packageOption;
  };
  settings = {
    programs.headroom = {
      enable = true;
      package = headroom;
      harness.package = harness;
      port = 9000;
      extraWrapArgs = [
        "--backend"
        "two words"
      ];
    };
  };
  replace = nixos settings;
  alongside = home (lib.recursiveUpdate settings {
    programs.headroom.wrapperName = "opencode-hr";
  });
  shell = devenv {
    headroom = {
      enable = true;
      package = headroom;
      harness.package = harness;
    };
  };
  disabled = nixos { };
  replacePackages = replace.config.environment.systemPackages;
  alongsidePackages = alongside.config.home.packages;
  shellPackages = shell.config.packages;
in
assert builtins.length disabled.config.environment.systemPackages == 0;
assert replace.config.programs.headroom.harness.command == "opencode";
assert builtins.length replacePackages == 2;
assert builtins.length alongsidePackages == 3;
assert builtins.elem harness alongsidePackages;
assert !(builtins.elem harness replacePackages);
assert builtins.length shellPackages == 2;
pkgs.runCommand "headroom-module-check"
  {
    nativeBuildInputs = [ pkgs.diffutils ];
  }
  ''
    ${lib.getExe' (builtins.elemAt replacePackages 1) "opencode"} --help > actual
    printf '%s\n' \
      '${harness}/bin/opencode' wrap opencode --port 9000 \
      --backend 'two words' -- --help > expected
    diff -u expected actual

    ${lib.getExe' (builtins.elemAt alongsidePackages 1) "opencode-hr"} prompt > actual
    printf '%s\n' \
      '${harness}/bin/opencode' wrap opencode --port 9000 \
      --backend 'two words' -- prompt > expected
    diff -u expected actual

    ${lib.getExe' (builtins.elemAt shellPackages 1) "opencode"} --version > actual
    printf '%s\n' \
      '${harness}/bin/opencode' wrap opencode --port 8787 \
      -- --version > expected
    diff -u expected actual
    touch "$out"
  ''
