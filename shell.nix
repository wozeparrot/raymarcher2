{ pkgs ? import <master> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    python3
    python3Packages.pygame
    cmake
    gcc

    vulkan-loader
    vulkan-headers

    shaderc

    fish
  ];

  LD_LIBRARY_PATH="${pkgs.vulkan-loader}/lib";
  shellHook = ''
    export PIP_PREFIX=$(pwd)/_build/pip_packages
    export PYTHONPATH="$PIP_PREFIX/${pkgs.python3.sitePackages}:$PYTHONPATH"
    export PATH="$PIP_PREFIX/bin:$PATH"
    unset SOURCE_DATE_EPOCH
  '';
}
