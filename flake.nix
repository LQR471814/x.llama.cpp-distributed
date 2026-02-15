{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.cudaSupport = true; # Critical: tells nixpkgs to prefer CUDA versions
      };
    in
    {
      devShells.${system}.default =
        let
          libs = with pkgs; [
            cudaPackages.cudatoolkit
            cudaPackages.cudnn
            linuxKernel.packages.linux_6_18.nvidia_x11
          ];
        in
        pkgs.mkShell {
          name = "cuda-python-env";
          packages =
            (with pkgs; [
              uv
              iproute2
              jq
              gnumake
              gcc
            ])
            ++ libs;
          # Nixpkgs now automates much of the LD_LIBRARY_PATH via 'autoAddDriverRunpath'
          # but a shellHook is often still needed for user-installed pip packages.
          shellHook = ''
            export CUDA_PATH=${pkgs.cudaPackages.cudatoolkit}
            export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libs}:$LD_LIBRARY_PATH"
            echo "Devshell activated."
          '';
        };
    };
}
