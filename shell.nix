{ pkgs ? import <nixpkgs> {} }:

let
  myAppEnv = (import ./default.nix {}).editableEnv;
in pkgs.mkShell {
  packages = [
    myAppEnv
    pkgs.python39
    pkgs.jq
    pkgs.curl
    (pkgs.poetry.override { python = pkgs.python39; })
  ];
}

