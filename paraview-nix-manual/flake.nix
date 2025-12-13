{
  description = "A simple flake to build ParaView from superbuild";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/6ebd17550c1323650ef2f80d80dd1e0d633d57b9";

  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
    };

    ospray = pkgs.stdenv.mkDerivation {
      pname = "ospray";
      version = "3.2.0";
      src = pkgs.fetchurl {
        url = "https://github.com/ospray/OSPRay/releases/download/v3.2.0/ospray-3.2.0.x86_64.linux.tar.gz";
        sha256 = "sha256-2GcOabR2LiTyqoNimviX6PM+occk4X5hOULAzMHHI74=";
      };
      nativeBuildInputs = [ pkgs.autoPatchelfHook ];
      buildInputs = [ pkgs.tbb pkgs.embree ];
      dontAutoPatchelf = true;
      installPhase = ''
        mkdir -p $out
        tar -xzf $src --strip-components=1 -C $out
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
        pkgs.bison
        pkgs.cmake
        # pkgs.cmakeWithGui
        pkgs.flex
        pkgs.perl
        pkgs.autoconf
        pkgs.ninja
        pkgs.git
        pkgs.tbb
        pkgs.embree
        pkgs.qt6.qtbase
        pkgs.qt6.qttools
        pkgs.mesa
        pkgs.libglvnd
        pkgs.xorg.libX11
        pkgs.xorg.libXext
        pkgs.xorg.libXrender
        pkgs.xorg.libxcb
        pkgs.xorg.xcbutil
        pkgs.pkg-config
        ospray
        pkgs.python3
        pkgs.hdf5
        pkgs.openmpi
      ];
      shellHook = ''
        export HOME="/home/vscode"
        export X11_ROOT="${pkgs.xorg.libX11.dev}"
        export CMAKE_PREFIX_PATH="${pkgs.xorg.libX11.dev}:${pkgs.xorg.libXext.dev}:${pkgs.xorg.libXrender.dev}:$CMAKE_PREFIX_PATH"
        export PKG_CONFIG_PATH="${pkgs.xorg.libX11.dev}/lib/pkgconfig:${pkgs.xorg.libXext.dev}/lib/pkgconfig:$PKG_CONFIG_PATH"
        export LD_LIBRARY_PATH="${pkgs.xorg.libX11.out}/lib:${pkgs.xorg.libXext.out}/lib:$LD_LIBRARY_PATH"
        
        echo $X11_ROOT

        echo Better, check port file...
        echo Add  /nix/store/20q72vi8wdb7j6p9sdnpi32477j6nv2z-libx11-1.8.12-dev/include/X11 to build/superbuild/paraview/src/VTK/CMake/patches/99/FindX11.cmake:134
        
        if [ ! -d "paraview-superbuild" ]; then
          echo "Cloning ParaView superbuild..."
          git clone --depth 1 --branch v6.0.1 https://gitlab.kitware.com/paraview/paraview-superbuild.git
          pushd paraview-superbuild
          git submodule update --init --recursive .
          popd
        fi
        
        mkdir -p build
        cd build
        cmake ../paraview-superbuild \
          -DCMAKE_BUILD_TYPE=Release \
          -DBUILD_SHARED_LIBS=ON \
          -DCMAKE_FIND_DEBUG_MODE=OFF \
          -G Ninja | grep X11

          # -DX11_ROOT_DIR=${pkgs.xorg.libX11.out}
          # -DPARAVIEW_BUILD_WITH_EXTERNAL_VTK=OFF
          # -DPARAVIEW_ENABLE_PYTHON=ON
          # -DX11_INCLUDE_PATH="$X11_INC_PATH"
          # -DX11_X11_INCLUDE_PATH="$X11_INC_PATH"
        
        ninja
        cd ..
        
        echo "ParaView superbuild ready."
        '';
      strictDeps = true;
    };
  };
}