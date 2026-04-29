{
  description = "Fast synthwave system information fetcher written in Zig";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          neonfetch = pkgs.callPackage ./nix/package.nix { };
        in
        {
          inherit neonfetch;
          default = neonfetch;
        });

      apps = forAllSystems (system: {
        neonfetch = {
          type = "app";
          program = "${self.packages.${system}.neonfetch}/bin/neonfetch";
        };
        default = self.apps.${system}.neonfetch;
      });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.zig_0_15
            ];
          };
        });
    };
}
