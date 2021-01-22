{ pkgs ? import <master> {} }:
pkgs.mkShell {
  buildInputs = with pkgs; [
    python3
    cmake
    gcc

    vulkan-loader
    vulkan-headers

    shaderc

    fish
  ];

  LD_LIBRARY_PATH="${pkgs.vulkan-loader}/lib";
}
