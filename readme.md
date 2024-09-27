# nixconf


## Usage

```sh
nix run github:nix-community/home-manager -- switch --flake .
```

After the first run, home-manager is available directly, and so you can do:

```sh
home-manager switch --flake .
```

## Updating dependencies

Since this repository is a nix flake (basically a self-contained nix package),
upgrading software is a single command away:

```sh
nix flake update .
```
