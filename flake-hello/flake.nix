{
  description = "A simple flake to test Nix installation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs";

  outputs = { self, nixpkgs }: {
    packages = {
      x86_64-linux = {
        hello = nixpkgs.legacyPackages.x86_64-linux.hello;
      };
    };
  };
}