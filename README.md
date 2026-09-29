# Headroom flake

Nix package and modules for [Headroom](https://github.com/headroomlabs-ai/headroom), a local proxy that compresses context for AI harness CLIs. The package uses the upstream prebuilt `headroom-ai` wheel, including its proxy dependencies, and nixpkgs' `ast-grep`.

Supported systems: x86_64-linux, aarch64-linux and aarch64-darwin. Current nixpkgs no longer supports x86_64-darwin.

## Package

```sh
nix build github:scarisey/headroom-flake
./result/bin/headroom --help
```

The package is also available as `packages.<system>.headroom`, and `nix develop` puts `headroom` on PATH.

## NixOS and Home Manager

Add `headroom.url = "github:scarisey/headroom-flake";` to your flake inputs. Pass `inputs` to your configuration via `specialArgs = { inherit inputs; };` (or an equivalent module argument), then import the appropriate module:

```nix
{ pkgs, inputs, ... }: {
  imports = [ inputs.headroom.nixosModules.default ];
  programs.headroom = {
    enable = true;
    harness.package = pkgs.opencode;
  };
}
```

For Home Manager, use `inputs.headroom.homeManagerModules.default` with the same `programs.headroom` options (and pass `inputs` via `extraSpecialArgs` if using standalone Home Manager). This installs Headroom and an `opencode` command that runs `headroom wrap opencode -- <args>`; the plain CLI remains in the wrapper's runtime closure but is not separately installed on PATH. For an additional `opencode-hr` command alongside the plain `opencode`:

```nix
programs.headroom = {
  enable = true;
  harness.package = pkgs.opencode;
  wrapperName = "opencode-hr";
};
```

You can supply any Nix package whose executable is supported by `headroom wrap`, for example a Copilot CLI package:

```nix
programs.headroom = {
  enable = true;
  harness.package = copilot-cli.packages.${pkgs.stdenv.hostPlatform.system}.default;
  extraWrapArgs = [ "--subscription" ]; # Copilot-specific option
};
```

`harness.command` defaults to the package's `meta.mainProgram` (or its package name). Override it if the executable/subcommand has a different name. `wrapperName` defaults to that command, replacing it; set a different name to install both. `port` defaults to `8787`; `extraWrapArgs` is a list of Headroom harness-specific flags, passed before `--` and the user's CLI arguments. The wrapper prepends the actual harness package's `bin` directory to PATH, so replacing the command does not cause recursion.

## devenv

```nix
{ inputs, pkgs, ... }: {
  imports = [ inputs.headroom.devenvModules.default ];
  headroom = {
    enable = true;
    harness.package = pkgs.opencode;
  };
}
```

Headroom's optional ML-based features may need additional dependencies; the CLI and `headroom wrap` proxy dependencies are included.
