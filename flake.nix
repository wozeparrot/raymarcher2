{
  description = "";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        rec {
          devShell = pkgs.mkShell {
            nativeBuildInputs = with pkgs; [
              python3
              python3Packages.pygame
              cmake
              gcc

              vulkan-loader
              vulkan-headers

              shaderc
            ];

            LD_LIBRARY_PATH = "${pkgs.vulkan-loader}/lib";
            shellHook = ''
              export PIP_PREFIX=$(pwd)/_build/pip_packages
              export PYTHONPATH="$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH"
              export PATH="$PIP_PREFIX/bin:$PATH"
              unset SOURCE_DATE_EPOCH
            '';
          };
        }
      );
}
