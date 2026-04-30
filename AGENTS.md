# AGENTS.md

## Project Shape
- `neonfetch` is a Linux-only Zig CLI; `src/main.zig` only calls `neonfetch.run()` from the module rooted at `src/root.zig`.
- `src/root.zig` wires CLI parsing (`cli.zig`), system collection (`collect.zig`), and rendering (`render.zig`); most behavior changes touch more than one of these files.
- System data collection intentionally reads Linux files and env directly (`/proc`, `/sys`, `/etc/os-release`, GTK config, Nix/Flatpak dirs) instead of spawning helper commands.
- Public package metadata is duplicated in `build.zig.zon` and `nix/package.nix`; keep versions in sync.

## Toolchain
- Required Zig version is `0.15.2` (`build.zig.zon`, CI, and Nix dev shell all agree).
- Use `nix develop` when the local Zig version is wrong; the dev shell provides `pkgs.zig_0_15`.
- The flake supports `x86_64-linux` and `aarch64-linux`; release builds target `x86_64-linux-musl` and `aarch64-linux-musl`.

## Commands
- Run all Zig tests: `zig build test`.
- Run the CLI locally: `zig build run -- [args]` (for example `zig build run -- --no-logo --only cpu,gpu,memory,disk`).
- Build optimized binary: `zig build -Doptimize=ReleaseFast`.
- CI formatting check is exactly `zig fmt --check build.zig src/main.zig src/root.zig`; if editing other Zig files, run `zig fmt` on those files too even though CI currently checks only this subset.
- Nix verification used by CI: `nix flake check --print-build-logs` and `nix build .#neonfetch --print-build-logs`.

## Source Coupling
- Adding or renaming an output field usually requires updates in `types.zig` (`FieldId`, `SystemInfo.field`), `collect.zig` defaults/fill logic, `render.zig` field list, `cli.zig` help/list output, and `README.md` CLI docs.
- Filter names are parsed case-insensitively; hyphens and spaces normalize to underscores. Existing aliases are `ip`, `displays`, `gpus`, and `disks`.
- `render.zig` contains non-ASCII logo art; preserve width-sensitive alignment and use `util.displayWidth`/`ArtWidth` when changing logos or rows.
- Color behavior is intentionally simple: `NO_COLOR` disables styling, `CLICOLOR_FORCE` forces it, otherwise color is enabled.

## Packaging And Release
- Nix packaging builds with `zig build -Doptimize=ReleaseFast --prefix "$out"` after setting `ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"`.
- Release workflow only publishes for tags matching `v*.*.*`; artifacts include the binary plus `README.md` and `LICENSE`.
- Build outputs and release artifacts are ignored (`.zig-cache/`, `zig-out/`, `result*`, `dist/`, `*.tar.gz`, `*.tar.gz.sha256`); do not commit them.
