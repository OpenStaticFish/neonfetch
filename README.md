# neonfetch

Fast synthwave system information for Linux terminals, written in Zig.

`neonfetch` is a lightweight neofetch-style CLI focused on startup speed, clean alignment, and a retro 80s neon look. It reads system data directly from `/proc`, `/sys`, `/etc/os-release`, and environment variables without spawning helper commands.

## Preview

Running `neonfetch` normally shows the distro logo (NixOS on NixOS, or the Linux penguin fallback).

### Character Preset

Use `neonfetch --preset character` to show the reference-inspired artwork. It is a 42-column, 35-color Unicode character with silver hair, red horns, a red-and-black outfit, and a floating mask. Quarter-blocks preserve fine details with a transparent background. Monochrome preview (`--preset character --plain --no-palette`):

```text
micqdf@hypr-nix
retro terminal telemetry

                             ▖         ▗▟▛   OS         NixOS 25.11 (Xantusia)
       ▗▌                   ▝▒  ▗▄▄  ▄▒▒▀    Host       B650M GAMING PLUS WIFI
       ▟▌ ▟                  ▓▙█▓▓██▒▒▀      Kernel     Linux 6.19.9-zen1
       ▜▌▐▙   ▄▄▟▓█▓▓▖       ▐▓▓▓▓▓▓▓█       Uptime     20h 50m
     ▝▙▞▒▓█▓▒▒░░░▒▒█▓▓       ▗▓██▒█▓▓▓       Packages   1287 (nix-system), 451 (nix-user), 4 (flatpak-system), 2 (flatpak-user)
      ▝▀▓█▒░░░░▒░▒▒░▒▙▖ ▗    ▝▜▓██▓▓▛▘       Shell      fish
        ▟░░▓▓▒░▒▒▒▒▒░▒▛▀▘      ▐▓▓▒▛         Display    (LG ULTRAWIDE): 2560x1080 in 29", 60 Hz [External]
     ▝▀▀▀▒░▒▒▒▒░▒▒▒▓▓▒▌        ▐███▘         Display    (27E1QA): 2560x1440 in 27", 60 Hz [External]
    ▗   ▐░░▓▓░▒▒▒▒██▓▓▌         ▀▀▘          Display    (VG271U M3): 2560x1440 in 27", 60 Hz [External]
 ▗▒▙▞░▖▄▒▒▒▓█▒▒▒▒▓░▒▒▒▌                      WM         Hyprland
 ▄▄▒░░▒▒▓▒▒▒▒▒▓▓▓▓▒▒▒▒▌▗▌▗▄▖                 Theme      Breeze-Dark [GTK3]
 ▗▒▓▒▒░▒▒▓▓▒▒▒▓▒▓▓█▓▓▓▙▟▙▒▒▙▄                Icons      breeze-dark [GTK3]
 ▀░░▒▒░▓███▓▓▓▓▓▓▓████▒▒▒▒▒▒▖                Font       Noto Sans 10 [GTK3]
   ▝▒▓█▓█▓▓█▓▓▓▓▓▓▓▓▓▓▒▒▒▒▒▒▌                Cursor     Bibata-Modern-Ice (24px)
    ▝▓▓▓███▒███▓▓▓█▒▀██▓▓▓▛▘                 Terminal   tty
     ▒▓▓░▒▒▓████▓█▙  ▝▀▀▀                    CPU        AMD Ryzen 7 7700 (16) @ 5.26 GHz
   ▗▟▒▒░░░▓████████▙                         GPU        RX 5700 XT RAW II [Discrete]
  ▗▒▒▒░░░▓██████████▖                        GPU        Raphael [Integrated]
 ▗▒▒▒▒░▓█████████████▖                       Memory     21.86 GiB / 30.47 GiB (71%)
 ▜░▒▒▓████████████████                       Swap       1.73 GiB / 31.23 GiB (5%)
   ▀▓▓▓█▓███████▓████▓                       Disk       (/): 0.00 GiB / 15.23 GiB (0%)
     ▜██▓▓▓▓▓▓▓█▓▓▓▓▓▓▌                      Disk       (/mnt/ssd2): 319.58 GiB / 931.51 GiB (34%)
     ████▒▒▒▒▒▒░▒▒▒▒▒▒▙▖                     Disk       (/nix): 1.25 TiB / 1.79 TiB (69%)
    ▟████▓░░▒▒░░░░░░░▒▒▒▄                    Local IP   192.168.0.20
   ▐████▒░░░░░░░░░░░░░░░▒▙▖                  Locale     en_GB.UTF-8
   ▐███▓░░▒░░░░░░░░░░░░░░▒▒▖
   ▝███▓░░░░░░░░░░░░░░░░░░▒▒
    ▝████▒▒▒░░▒░░░▒░▒░░░░▒▒▒▌
      ▀▜███▓▒▒█████░▓▒█▓▒▒▒▒▌
           ▒▒▒░░▒▒▓▒▒▒▓████▒▌
       ▒   ░░░░░░░░▒▒▒▒▒▒▓████▖
       ░  ▗░░░▒▒▒▒▒▒▒▒▒▒▒▒▀▝▀██▖
       ▜▒▄▄▒░░░▒▒▒▒▒▒▒▒▛▀    ▝▓▌
         ▀▀▀░░░▀▛▀▀▀▜▒▒▌      ▓▌
            ▜░░▖    ▐▒▒▌     ▟▀
             ░░▌    ▐▒▒▖    ▀
             ▜░▙    ▟▒▒▌
            ▗▒░░▌  ▗▓▓▓▓
             ▓░▒▙ ▗▓▒▒▓▓
             ▓▒▒▒▖▐████▌
             ▓▓▓▓▓ ▜██▀▘
              ▜██▀
```

## Features

- Native Zig binary with no runtime dependencies.
- Fast data collection with no shell-outs.
- Synthwave ANSI color output with `NO_COLOR` support.
- Distro logos by default, with optional full-color and monochrome character artwork via `--preset character`.
- Linux system details: OS, host, kernel, uptime, packages, shell, displays, WM, GTK theme, icons, font, cursor, terminal, CPU, GPUs, memory, swap, disks, local IP, and locale.
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

## CLI Options

```sh
neonfetch --help
neonfetch --version
neonfetch fields
neonfetch categories
neonfetch --preset character
neonfetch --no-logo --only cpu,gpu,memory,disk
neonfetch --hide packages,local_ip --no-palette
neonfetch --raw --only cpu
neonfetch --format json
neonfetch --format csv --only os,cpu,memory
```

- `help` or `--help` shows usage, commands, filters, and examples.
- `version` or `--version` prints the release version.
- `fields` or `--list-fields` lists filterable fields.
- `categories` or `--list-categories` lists filterable categories.
- `--preset <name>` selects artwork: `default` (the distro logo) or `character`. Also accepts `--preset=character`. Preset names are case-insensitive and affect only `pretty` output.
- `--no-logo` hides the logo or preset artwork, including when `--preset character` is selected.
- `--no-header` hides the `user@host` header.
- `--no-palette` hides the color palette footer.
- `--plain` or `--no-color` disables ANSI styling.
- `--color` forces ANSI styling.
- `--raw` prints only field values with no logo, header, or palette.
- `--format <fmt>` sets output format: `pretty` (default), `raw`, `json`, or `csv`.
- `--only <list>` shows only selected fields or categories.
- `--hide <list>` hides selected fields or categories.

Filter lists are comma-separated. Supported fields are `os`, `host`, `kernel`, `uptime`, `packages`, `shell`, `display`, `wm`, `theme`, `icons`, `font`, `cursor`, `terminal`, `cpu`, `gpu`, `memory`, `swap`, `disk`, `local_ip`, and `locale`. Supported categories are `identity`, `system`, `desktop`, `hardware`, `package`, `usage`, `storage`, and `network`. Names are case-insensitive; hyphens and spaces are treated like underscores. Aliases include `ip`, `displays`, `gpus`, and `disks`.

## License

MIT
