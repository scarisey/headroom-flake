{ lib }:
rec {
  mkOptions =
    { pkgs, cfg }:
    {
      enable = lib.mkEnableOption "Headroom-wrapped harness CLI";

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.callPackage ../package.nix { };
        defaultText = lib.literalExpression "pkgs.callPackage ../package.nix { }";
        description = "Headroom package used to run the local proxy.";
      };

      harness = {
        package = lib.mkOption {
          type = lib.types.package;
          description = "Nix package providing the CLI to wrap (for example pkgs.opencode). Required when enabled.";
          example = lib.literalExpression "pkgs.opencode";
        };

        command = lib.mkOption {
          type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9._+-]*";
          default = builtins.baseNameOf (lib.getExe cfg.harness.package);
          defaultText = lib.literalExpression "builtins.baseNameOf (lib.getExe cfg.harness.package)";
          description = "CLI executable name and corresponding `headroom wrap` subcommand. Defaults to the package's main program.";
          example = "opencode";
        };
      };

      wrapperName = lib.mkOption {
        type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9._+-]*";
        default = cfg.harness.command;
        defaultText = lib.literalExpression "cfg.harness.command";
        description = "Installed wrapped command name. Set to another name (e.g. opencode-hr) to also install the plain harness CLI.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8787;
        description = "Local Headroom proxy port.";
      };

      extraWrapArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "--backend"
          "anyllm"
        ];
        description = "Additional options to `headroom wrap <command>` before the harness arguments.";
      };
    };

  mkWrapper =
    { pkgs, cfg }:
    pkgs.writeShellScriptBin cfg.wrapperName ''
      export PATH="${lib.makeBinPath [ cfg.harness.package ]}:$PATH"
      exec "${cfg.package}/bin/headroom" wrap ${lib.escapeShellArg cfg.harness.command} \
        --port ${toString cfg.port} \
        ${lib.escapeShellArgs cfg.extraWrapArgs} \
        -- "$@"
    '';

  mkPackages =
    { pkgs, cfg }:
    [
      cfg.package
      (mkWrapper { inherit pkgs cfg; })
    ]
    ++ lib.optional (cfg.wrapperName != cfg.harness.command) cfg.harness.package;
}
