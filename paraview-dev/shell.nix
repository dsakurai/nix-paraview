let
  pkgs = import <nixpkgs> {};
  paraview = pkgs.callPackage ./default.nix {};
  src = paraview.src;
in
pkgs.mkShell {
  nativeBuildInputs = paraview.nativeBuildInputs;
  buildInputs = (paraview.buildInputs or []) ++ [ pkgs.qt6.qtbase ];

  shellHook = ''
    if [ ! -d ParaView-v6.0.1 ]; then
      echo "Unpacking ParaView source..."
      cp ${src} ./ParaView-v6.0.1.tar.xz # I don't remember how I exactly downloaded this source... You can read default.nix to figure out the URL in any case...
      tar xf ParaView-v6.0.1.tar.xz
    fi
  '';
}