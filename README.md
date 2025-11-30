# Nix GUI Programs Demo

This demo shows how to use Nix to build, install, and run GUI programs in a dev container.

## Prerequisites
- Nix package manager (pre-installed in this dev container)
- DevContainer

## Development and debugging

Enter the directory `paraview-dev` and execute `nix-shell` from shell.

If a nix file fails,

- Use a single-user install, so that you can edit build files with your user account.

Then you need to do...

```
nix profile add . --keep-failed
```
to keep the failed directory.

and, (add build dependencies manually in pkgs.mkShell? may be unnecessary?) and do
```
nix shell
```

to recover the shell environment.
