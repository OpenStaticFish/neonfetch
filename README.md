# neonfetch

Fast synthwave system information for Linux terminals, written in Zig.

`neonfetch` is a lightweight neofetch-style CLI focused on startup speed, clean alignment, and a retro 80s neon look. It reads system data directly from `/proc`, `/sys`, `/etc/os-release`, and environment variables without spawning helper commands.

## Preview

```text
micqdf@hypr-nix
retro terminal telemetry

        .            .          OS         NixOS 25.11 (Xantusia)
      .:;:.        .:;:.        Kernel     Linux 6.19.9-zen1
    .:;;;;:.    .:;;;;:.        Arch       x86_64
  .:;;;;;;;;:..:;;;;;;;;:.      Uptime     11d 18h 27m
 .:;;;;;;'        ';;;;;;:.     Desktop    Hyprland
 :;;;;;'   .-==-.   ';;;;;:     WM         Hyprland
 :;;;;   .'  __  '.   ;;;;:     Shell      fish
 ';;;;.  |  (__)  |  .;;;;'     CPU        AMD Ryzen 7 7700 8-Core Processor
  ';;;;:. '._/ _.' .:;;;;'      GPU        RX 5700 XT RAW II (amdgpu)
    ';;;;:..____..:;;;;'        Memory     16295 MiB / 31198 MiB (52%)
      ';;;;;;;;;;;;;;'          Display    2560x1080 @ card1-HDMI-A-1
        '::;;;;;;::'            Packages   1287 system binaries
                                Terminal   xterm-256color / wayland
```

## Features

- Native Zig binary with no runtime dependencies.
- Fast data collection with no shell-outs.
- Synthwave ANSI color output with `NO_COLOR` support.
- Linux system details: OS, kernel, arch, uptime, desktop, WM, shell, CPU, GPU, memory, display, packages, and terminal.
- GPU model lookup from PCI IDs when available, with targeted fallbacks.
- Nix flake package, app, and dev shell.
- GitHub Actions CI and release binaries.

## Install

### Nix Flake

Run directly:

```sh
nix run github:OpenStaticFish/neonfetch
```

Install into a profile:

```sh
nix profile install github:OpenStaticFish/neonfetch
```

Use in a NixOS config:

```nix
{
  inputs.neonfetch.url = "github:OpenStaticFish/neonfetch";

  outputs = { nixpkgs, neonfetch, ... }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          {
            environment.systemPackages = [
              neonfetch.packages.${system}.default
            ];
          }
        ];
      };
    };
}
```

Use in Home Manager:

```nix
{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.neonfetch.packages.${pkgs.system}.default
  ];
}
```

### Release Binary

Download a Linux tarball from the [releases page](https://github.com/OpenStaticFish/neonfetch/releases), then place `neonfetch` somewhere on your `PATH`.

### From Source

Requires Zig `0.15.2`.

```sh
zig build -Doptimize=ReleaseFast
./zig-out/bin/neonfetch
```

## Development

Run tests:

```sh
zig build test
```

Run locally:

```sh
zig build run
```

Enter a Nix dev shell:

```sh
nix develop
```

Build with Nix:

```sh
nix build
```

## Environment

- `NO_COLOR=1` disables ANSI styling.
- `CLICOLOR_FORCE=1` forces color output.

## License

MIT
