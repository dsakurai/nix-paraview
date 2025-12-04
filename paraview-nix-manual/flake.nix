{
  description = "A simple flake to test Nix installation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/c8996fc1e6ef04c4049136c0363a8a4243f37c32";

  outputs = { self, nixpkgs }: {
    packages = {
      x86_64-linux = let
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
          nativeBuildInputs = [ pkgs.autoPatchelfHook ];
          buildInputs = [ pkgs.tbb pkgs.embree ];
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

        # Add ospray to buildInputs for VTK
        # myVtk = pkgs.vtk-full.overrideAttrs (old: {
        #   buildInputs = (old.buildInputs or []) ++ [ ospray ];
        #   cmakeFlags = (old.cmakeFlags or []) ++ [
        #     "-DVTK_MODULE_ENABLE_VTK_RENDERINGRAYTRACING=WANT"
        #     "-Dospray_DIR=${ospray}/lib/cmake/ospray"
        #     
        #     # Fails with OSPRay
        #     "-DVTK_MODULE_ENABLE_VTK_IOIOSS=WANT" # Suspicious..
        #     "-DVTK_MODULE_ENABLE_VTK_ioss=WANT"
        #     "-DVTK_IOSSMODULE_ENABLE=WANT"
        #   ];
        #   # Limit parallel jobs to 1
        #   # enableParallelBuilding = false; # Save RAM
        #   # NIX_BUILD_CORES = 1; # Save RAM
        # });

        # myParaview = pkgs.paraview.override {
        #   vtk-full = myVtk;
        # };

        # myParaviewWithFlags = pkgs.paraview.overrideAttrs (old: {
        #   cmakeFlags = old.cmakeFlags ++ [
        #     "-Dospray_DIR=${ospray}/lib/cmake/ospray"
        #     (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_RAYTRACING" true)
        #     (pkgs.lib.cmakeBool "PARAVIEW_USE_MPI" false)
        #     (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_WEB" false)
        #     (pkgs.lib.cmakeBool "PARAVIEW_USE_EXTERNAL_VTK" false)
        #   ];
        # });
      in {
        #paraview = pkgs.symlinkJoin {
        #
        #  # I could use nixGL, but mesa is probably fine assuming we can use CPU rendering with ParaView https://github.com/nix-community/nixGL

        #  name = "paraview-with-osmesa";
        #  paths = [ myParaviewWithFlags ];
        #  buildInputs = [ pkgs.makeWrapper ];
        #  postBuild = ''
        #    wrapProgram $out/bin/paraview \
        #      --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.mesa pkgs.libglvnd ]}" \
        #      --set __GLX_VENDOR_LIBRARY_NAME mesa \
        #      --set GALLIUM_DRIVER llvmpipe \
        #      --set LIBGL_ALWAYS_SOFTWARE 1 \
        #      --set MESA_GL_VERSION_OVERRIDE 3.3 \
        #      --set FONTCONFIG_FILE "${pkgs.fontconfig.out}/etc/fonts/fonts.conf" \
        #      --set LC_ALL C.UTF-8
        #  '';
        #};
        default = self.packages.x86_64-linux.paraview;
      };
    };

    devShells.x86_64-linux.default = let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in pkgs.mkShell {
      buildInputs = [
        pkgs.cmake
        pkgs.ninja
        pkgs.tbb
        pkgs.embree
        pkgs.qt6.qtbase
        pkgs.qt6.qttools
        pkgs.mesa
        pkgs.libglvnd
        # pkgs.qt6Packages.wrapQtAppsHook  # <-- fix here
        # add any other dependencies you need for debugging/building
      ];
    };
  };
}