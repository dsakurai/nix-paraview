# Nix GUI Programs Demo

This demo shows how to use Nix to build, install, and run GUI programs in a dev container.

## Prerequisites
- Nix package manager (pre-installed in this dev container)
- DevContainer

## Installing ParaView with Conan

TODO:
- Don't use system packages...
- For that, can we use mesa instead of Debian packages?
- Or nix?

## Manually starting the Nix Daemon

For a single-user install,
```
sudo groupadd nixbld
for i in $(seq 1 10); do
  sudo useradd -g nixbld -G nixbld -M -N -s /sbin/nologin nixbld$i || true
done
```

```
# sudo /usr/local/share/nix-entrypoint.sh # Didn't work, although it was found on https://github.com/devcontainers/features/tree/main/src/nix
sudo /nix/var/nix/profiles/default/bin/nix-daemon & # This one seems to work.
```

## Development and debugging

To edit a file in store, you need to understand that files in the Nix store are **immutable** - you cannot directly edit them. However, you can work with the source in your workspace. Here are your options:

### Option 1: Copy the package definition to your workspace

```bash
# Copy the Nix package definition to your workspace
cp /nix/store/9rf7z9hhnxqvbf5i04labfsxill2zhyl-source/pkgs/by-name/pa/paraview/package.nix ./paraview-package.nix

# Edit it
code ./paraview-package.nix
```

Then create a flake.nix or `default.nix` that uses your modified version.

### Option 2: Create an override in a flake

Create a flake.nix in your workspace:

````nix
{
  description = "Custom ParaView build";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
  in {
    packages.x86_64-linux.default = pkgs.paraview.overrideAttrs (oldAttrs: {
      # Add your modifications here
      # For example:
      # cmakeFlags = oldAttrs.cmakeFlags ++ [ "-DPARAVIEW_USE_PYTHON=ON" ];
    });
  };
}
````

### Option 3: Extract and modify the source locally

```bash
# Find the nixpkgs revision being used
nix flake metadata nixpkgs

# Clone nixpkgs to your workspace
git clone https://github.com/NixOS/nixpkgs.git
cd nixpkgs

# Find and edit the file
code pkgs/by-name/pa/paraview/package.nix
```

Then reference your local nixpkgs in your flake:

````nix
{
  inputs.nixpkgs.url = "path:./nixpkgs";
  # ... rest of your flake
}
````

### Option 4: Use `nix edit`

```bash
# This will copy the derivation to a temporary location and open it
nix edit nixpkgs#paraview
```

The most practical approach for your workspace is **Option 1 or 2**, depending on whether you want to completely rewrite the package or just override specific attributes.

### but can I run, say, cmake manually for the build of nixpkgs#paraview?

Yes! You can absolutely run `cmake` manually in the development shell. Here's how:

### Enter the ParaView development shell and build manually

````nix
{
  description = "ParaView manual build environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShells.${system}.default = pkgs.mkShell {
      inputsFrom = [ pkgs.paraview ];
      
      shellHook = ''
        echo "ParaView development shell"
        echo "Source is available at: $src"
        echo ""
        echo "To build manually:"
        echo "  unpackPhase    # Extracts source to current directory"
        echo "  cd paraview-*  # Enter source directory"
        echo "  configurePhase # Runs cmake with Nix's flags"
        echo "  buildPhase     # Runs make/ninja"
        echo ""
        echo "Or run individual commands like:"
        echo "  cmake -B build -S ."
        echo "  cmake --build build"
      '';
    };
  };
}
````

### Usage

```bash
cd paraview-12-06
nix develop

# Option A: Use Nix's phases
unpackPhase
cd paraview-*
configurePhase  # This runs cmake with all the flags Nix uses
buildPhase      # This runs the actual build

# Option B: Run cmake manually
unpackPhase
cd paraview-*
cmake -B build -S . -GNinja
cmake --build build

# Option C: Run cmake with specific flags
cmake -B build -S . \
  -DCMAKE_BUILD_TYPE=Debug \
  -DPARAVIEW_USE_PYTHON=ON \
  -GNinja
ninja -C build
```

The `inputsFrom = [ pkgs.paraview ]` gives you:
- All build dependencies (cmake, ninja, Qt, VTK, etc.)
- All environment variables set correctly
- The source accessible via `$src` variable
- The phase functions (`unpackPhase`, `configurePhase`, etc.)

You can inspect what cmake flags Nix uses:

```bash
nix develop
echo $cmakeFlags
```

This gives you full manual control while still having all dependencies properly configured!

---

```
vscode@f39436dd350c:/workspaces/devcontainer-nix-official/paraview-12-06$ cp /nix/store/9rf7z9hhnxqvbf5i04labfsxill2zhyl-source/pkgs/by-name/pa/paraview/package.nix ./paraview-package.nix
                                                                   
# View the cmakeFlags section
grep -A 100 "cmakeFlags" ./paraview-package.nix
  cmakeFlags = [
    (lib.cmakeBool "PARAVIEW_VERSIONED_INSTALL" false)
    (lib.cmakeBool "PARAVIEW_BUILD_WITH_EXTERNAL" true)
    (lib.cmakeBool "PARAVIEW_USE_EXTERNAL_VTK" true)
    (lib.cmakeBool "PARAVIEW_USE_QT" true)
    (lib.cmakeBool "PARAVIEW_USE_MPI" true)
    (lib.cmakeBool "PARAVIEW_USE_PYTHON" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_WEB" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_CATALYST" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_VISITBRIDGE" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_ADIOS2" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_FFMPEG" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_FIDES" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_ALEMBIC" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_LAS" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_GDAL" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_PDAL" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_OPENTURNS" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_MOTIONFX" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_OCCT" true)
    (lib.cmakeBool "PARAVIEW_ENABLE_XDMF3" true)
    (lib.cmakeFeature "CMAKE_INSTALL_BINDIR" "bin")
    (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    (lib.cmakeFeature "CMAKE_INSTALL_INCLUDEDIR" "include")
    (lib.cmakeFeature "CMAKE_INSTALL_DOCDIR" "share/paraview/doc")
  ];

  postInstall = ''
    install -Dm644 ${doc} $out/share/paraview/doc/${doc.name}
    mkdir -p $out/share/paraview/examples
    tar --strip-components=1 -xzf ${examples} -C $out/share/paraview/examples
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    install -Dm644 ../Qt/Components/Resources/Icons/pvIcon.svg $out/share/icons/hicolor/scalable/apps/paraview.svg
  ''
  + lib.optionalString stdenv.hostPlatform.isDarwin ''
    ln -s ../Applications/paraview.app/Contents/MacOS/paraview $out/bin/paraview
  '';

  passthru.tests = {
    cmake-config = testers.hasCmakeConfigModules {
      moduleNames = [ "ParaView" ];

      package = finalAttrs.finalPackage;

      nativeBuildInputs = [
        qt6Packages.wrapQtAppsHook
      ];
    };
  };

  meta = {
    description = "3D Data analysis and visualization application";
    homepage = "https://www.paraview.org";
    changelog = "https://www.kitware.com/paraview-${lib.concatStringsSep "-" (lib.versions.splitVersion finalAttrs.version)}-release-notes";
    mainProgram = "paraview";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [
      guibert
      qbisi
    ];
  };
})
```

Or

```
    devShells.${system}.default = pkgs.mkShell {
      inputsFrom = [ paraview ];

      # Inherit phases and attributes from paraview
      inherit (paraview) src cmakeFlags;

      # Modify postPatch - run original first, then add your changes
      postPatch = (paraview.postPatch or "") + ''
        echo "Running custom postPatch modifications..."
        
        # Add your custom postPatch commands here
        # For example:
        # substituteInPlace CMakeLists.txt \
        #   --replace "old_value" "new_value"
        
        # Or apply custom patches:
        # patch -p1 < ${./my-custom.patch}
      '';

```

Or

```
nix repl
```

Then in the repl

```
:lf nixpkgs
paraview.cmakeFlags
paraview.configurePhase
```

The configure phase of nix for CMake is stored in, e.g., `/nix/store/2lrbixyw95bjg0x1aav648r0h0zsj2jl-cmake-4.1.1/nix-support/setup-hook`

##

Enter the directory `paraview-dev` and execute `nix-shell` from shell.

If a nix file fails,

- Use a single-user install, so that you can edit build files with your user account.

Then you need to do...

```
nix profile add . --keep-failed
```
to keep the failed directory.

and, (add build dependencies manually in pkgs.mkShell's nativeBuildInputs, may be unnecessary?) and do
```
nix develop
```

to recover the shell environment.

Remember to execute `nix develop` EVERYTIME you change flake.nix.
