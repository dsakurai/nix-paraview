{
  description = "A simple flake to test Nix installation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/25.05";

  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };
    
    # Minimal ospray derivation (replace version/hash as needed)
    ospray = pkgs.stdenv.mkDerivation {
      pname = "ospray";
      version = "3.2.0";
      src = pkgs.fetchurl {
        url = "https://github.com/ospray/OSPRay/releases/download/v3.2.0/ospray-3.2.0.x86_64.linux.tar.gz";
        sha256 = "sha256-2GcOabR2LiTyqoNimviX6PM+occk4X5hOULAzMHHI74=";
      };
      nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.pkg-config  pkgs.curl];
      buildInputs = [ pkgs.tbb pkgs.embree pkgs.curl ];
      dontAutoPatchelf = true;
      installPhase = ''
        mkdir -p $out
        tar -xzf $src --strip-components=1 -C $out
        # Only patch the libraries you actually need (core OSPRay)
        for f in $out/lib/libospray.so* $out/lib/cmake/ospray/*; do
          if [ -f "$f" ]; then
            patchelf --set-rpath ${pkgs.lib.makeLibraryPath [ pkgs.tbb pkgs.embree ]} "$f" || true
          fi
        done
      '';
    };
  in {
    packages.x86_64-linux.default = ospray;

    devShells.x86_64-linux.default = pkgs.mkShell {
      nativeBuildInputs = [
        pkgs.curl
        pkgs.pkg-config
        pkgs.cmake
        pkgs.perl
      ];
      buildInputs = [
        pkgs.curl
        pkgs.cmake
        pkgs.linuxHeaders
        pkgs.perl
        #pkgs.ninja
        # pkgs.pkg-config
        #pkgs.tbb
        #pkgs.embree
        #pkgs.qt6.qtbase
        #pkgs.qt6.qttools
        #pkgs.mesa
        #pkgs.libglvnd
        #pkgs.qt6Packages.wrapQtAppsHook
        pkgs.vcpkg
        ospray
      ];
      shellHook = ''
        # export PKG_CONFIG_EXECUTABLE="${pkgs.pkg-config}/bin/pkg-config"
        export "ospray_DIR=${ospray}/lib/cmake/ospray"
        export CMAKE_PREFIX_PATH="${ospray}:$CMAKE_PREFIX_PATH"
        export CMAKE_LIBRARY_PATH="${ospray}/lib:$CMAKE_LIBRARY_PATH"
        export CMAKE_INCLUDE_PATH="${ospray}/include:$CMAKE_INCLUDE_PATH"
        export CURL="${pkgs.curl}/bin/curl"
        export VCPKG_CURL="${pkgs.curl}/bin/curl"
        echo "vcpkg and ospray are available. To use vcpkg, run: vcpkg install"
      '';
    };
  };
}