{
  description = "ParaView manual build environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/c8996fc1e6ef04c4049136c0363a8a4243f37c32";

  outputs = { nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    paraview = pkgs.paraview;
    
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
    devShells.${system}.default = paraview.overrideAttrs (oldAttrs: {
      
      # Modify postPatch - run original first, then add your changes
      postPatch = ''
        # When building paraview with external vtk, we can not infer resource_dir
        # from the path of vtk's libraries. Thus hardcoding the resource_dir.
        # See https://gitlab.kitware.com/paraview/paraview/-/issues/23043.
        # substituteInPlace Remoting/Core/vtkPVFileInformation.cxx \
        #   --replace-fail "return resource_dir;" "return \"$out/share/paraview\";"

        # fix build against qt-6.10.1
        substituteInPlace Qt/Core/{pqFlatTreeViewEventTranslator,pqQVTKWidgetEventTranslator}.cxx \
          ThirdParty/QtTesting/vtkqttesting/{pqAbstractItemViewEventTranslator,pqBasicWidgetEventTranslator}.cxx \
          --replace-fail "mouseEvent->buttons()" "static_cast<int>(mouseEvent->buttons())" \
          --replace-fail "mouseEvent->modifiers()" "static_cast<int>(mouseEvent->modifiers())"
        echo "Running custom postPatch modifications..."
      '';

      nativeBuildInputs = [
        pkgs.cmake
        pkgs.ninja
        pkgs.qt6Packages.wrapQtAppsHook
        pkgs.makeWrapper
        pkgs.xorg.xeyes # Useful for debugging GUI
        
        # For nix develop shell
        pkgs.uv
      ];
      
      propagatedBuildInputs = [
        pkgs.qt6Packages.qttools
        pkgs.qt6Packages.qt5compat
        pkgs.protobuf
        pkgs.nlohmann_json
        # pkgs.vtk-full
        pkgs.mesa
        ospray
        pkgs.libglvnd
        pkgs.xorg.libxcb
        pkgs.xorg.xcbutilcursor
        pkgs.xorg.xcbutilimage
        pkgs.xorg.xcbutilkeysyms
        pkgs.xorg.xcbutilrenderutil
        pkgs.xorg.xcbutilwm
        
        # Python
        pkgs.python311
        pkgs.python311Packages.numpy
        # pkgs.python311Packages.wslink
        # pkgs.python311Packages.matplotlib # Conflicts with tkinter 9
        # pkgs.python311Packages.mpi4py
      ];
      
      cmakeFlags = [
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_RAYTRACING" true)

        (pkgs.lib.cmakeBool "PARAVIEW_VERSIONED_INSTALL" false)
        (pkgs.lib.cmakeBool "PARAVIEW_BUILD_WITH_EXTERNAL" false)
        (pkgs.lib.cmakeBool "PARAVIEW_USE_EXTERNAL_VTK" false)
        (pkgs.lib.cmakeBool "PARAVIEW_USE_QT" true)
        (pkgs.lib.cmakeBool "PARAVIEW_USE_MPI" false)
        (pkgs.lib.cmakeBool "PARAVIEW_USE_PYTHON" true)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_WEB" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_CATALYST" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_VISITBRIDGE" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_ADIOS2" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_FFMPEG" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_FIDES" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_ALEMBIC" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_LAS" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_GDAL" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_PDAL" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_OPENTURNS" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_MOTIONFX" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_OCCT" false)
        (pkgs.lib.cmakeBool "PARAVIEW_ENABLE_XDMF3" false)
        (pkgs.lib.cmakeFeature "CMAKE_INSTALL_BINDIR" "bin")
        (pkgs.lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
        (pkgs.lib.cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
        (pkgs.lib.cmakeFeature "CMAKE_INSTALL_DOCDIR" "share/paraview/doc")
        "-GNinja"
        "-Dospray_DIR=${ospray}/lib/cmake/ospray"
      ];
      
      # Don't build nor install automatically.
      # Not sure if these really have an effect.
      dontBuild   = true;
      dontInstall = false;

      shellHook = ''
        # Set up Qt and OpenGL environment
        export QT_PLUGIN_PATH="${pkgs.qt6Packages.qtbase}/${pkgs.qt6Packages.qtbase.qtPluginPrefix}"
        export QT_QPA_PLATFORM_PLUGIN_PATH="${pkgs.qt6Packages.qtbase}/${pkgs.qt6Packages.qtbase.qtPluginPrefix}/platforms"
        export QT_QPA_PLATFORM=offscreen
        export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [ 
          pkgs.mesa 
          pkgs.libglvnd 
          pkgs.xorg.xcbutilcursor
          pkgs.xorg.libxcb
          pkgs.qt6Packages.qtbase
        ]}:$LD_LIBRARY_PATH"
        export __GLX_VENDOR_LIBRARY_NAME=mesa
        export GALLIUM_DRIVER=llvmpipe
        export LIBGL_ALWAYS_SOFTWARE=1
        export MESA_GL_VERSION_OVERRIDE=3.3
        export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
        export LC_ALL=C.UTF-8
        
        echo "ParaView development shell"
        echo "Source is available at: $src"
        echo ""
        echo "To build manually:"
        echo "  unpackPhase"
        echo "  cd ParaView-v6.0.1"
        echo "  patchPhase"
        echo "  mkdir -p build && cd build"
        echo "  cmake \$cmakeFlags .."
        echo "  ninja"
        echo ""
        echo ""
        echo "CMake flags: $cmakeFlags"
        
        echo "Run ParaView-v6.0.1/build/bin/paraview with nix develop (without -i)"
        
        # Set up uv
        export UV_PYTHON="${pkgs.python311}/bin/python3"
        
        echo "Even with `uv venv`, this will create a venv with numpy. It is available in PYTHONPATH since nix exposes packages that way." 

        echo "To use Python venv, you can do"
        echo "uv init myproject && cd myproject && source .venv/bin/activate"
        echo "paraview --venv .venv"
      '';
    });
  };
}