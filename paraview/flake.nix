{
  description = "A simple flake to test Nix installation";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/c8996fc1e6ef04c4049136c0363a8a4243f37c32";

  outputs = { self, nixpkgs }: {
    packages = {
      x86_64-linux = let
        pkgs = import nixpkgs {
          system = "x86_64-linux";
        };
        # Override cmakeFlags here
        myParaview = pkgs.paraview.overrideAttrs (old: {
          cmakeFlags = old.cmakeFlags ++ [
            # Add your custom flags here, for example:
            (pkgs.lib.cmakeBool "PARAVIEW_USE_MPI" false)
            (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_WEB" false)
          ];
        });
      in {
        paraview = pkgs.symlinkJoin {
        
          # I could use nixGL, but mesa is probably fine assuming we can use CPU rendering with ParaView https://github.com/nix-community/nixGL

          name = "paraview-with-osmesa";
          paths = [ myParaview ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/paraview \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [ pkgs.mesa pkgs.libglvnd ]}" \
              --set __GLX_VENDOR_LIBRARY_NAME mesa \
              --set GALLIUM_DRIVER llvmpipe \
              --set LIBGL_ALWAYS_SOFTWARE 1 \
              --set MESA_GL_VERSION_OVERRIDE 3.3 \
              --set FONTCONFIG_FILE "${pkgs.fontconfig.out}/etc/fonts/fonts.conf" \
              --set LC_ALL C.UTF-8
          '';
        };
        default = self.packages.x86_64-linux.paraview;
      };
    };
  };
}