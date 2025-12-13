{
  description = "ParaView manual build environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/c8996fc1e6ef04c4049136c0363a8a4243f37c32";

  outputs = { nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
    paraview = pkgs.paraview;
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
        # vtk-full.vtkPackages.python3Packages.pythonRecompileBytecodeHook
      ];
      
      propagatedBuildInputs = [
        pkgs.qt6Packages.qttools
        pkgs.qt6Packages.qt5compat
        pkgs.protobuf
        pkgs.nlohmann_json
        # vtk-full
      ];
      
      cmakeFlags = [
        (pkgs.lib.cmakeBool "PARAVIEW_VERSIONED_INSTALL" false)
        (pkgs.lib.cmakeBool "PARAVIEW_BUILD_WITH_EXTERNAL" false)
        (pkgs.lib.cmakeBool "PARAVIEW_USE_EXTERNAL_VTK" false)
        (pkgs.lib.cmakeBool "PARAVIEW_USE_QT" true)
        (pkgs.lib.cmakeBool "PARAVIEW_USE_MPI" false)
        (pkgs.lib.cmakeBool "PARAVIEW_USE_PYTHON" false)
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
      ];
      
      dontBuild   = true;
      dontInstall = true;

      shellHook = ''
      
        # Source the CMake setup hook to get configurePhase
        # source ${pkgs.cmake}/nix-support/setup-hook
        
        echo "${pkgs.cmake}"



        echo "ParaView development shell"
        echo "Source is available at: $src"
        echo ""
        echo "To build manually:"
        echo "  unpackPhase    # Extracts source to current directory"
        echo "  patchPhase     # Applies patches"
        echo "  cd paraview-*  # Enter source directory"
        echo "  configurePhase # Runs cmake with Nix's flags"
        echo "  buildPhase     # Runs make/ninja"
        echo ""
        echo "CMake flags: $cmakeFlags"

        # unpackPhase
        mkdir -p ParaView-v6.0.1/build
        cd ParaView-v6.0.1/build
      '';
    });
  };
}