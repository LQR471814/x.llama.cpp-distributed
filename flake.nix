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
      defaultLibs = with pkgs; [
        openssl
      ];
      deps = with pkgs; [
        uv
        iproute2
        jq
        gnumake
        gcc
        pkg-config
        bc
      ];
    in
    {
      devShells.${system} =
        let
          libs = defaultLibs;
        in
        {
          cuda = pkgs.mkShell {
            name = "cuda-python-env";
            buildInputs = libs;
            packages = deps;
            # Nixpkgs now automates much of the LD_LIBRARY_PATH via 'autoAddDriverRunpath'
            # but a shellHook is often still needed for user-installed pip packages.
            shellHook = ''
              export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libs}:/run/opengl-driver/lib:$LD_LIBRARY_PATH"
              export EXTRA_CMAKE_FLAGS="-DGGML_CUDA=ON"
              echo "Devshell activated."
            '';
          };
          mkl =
            let
              libs =
                with pkgs;
                [
                  openblas
                ]
                ++ defaultLibs;
            in
            pkgs.mkShell {
              name = "mkl-python-env";
              buildInputs = libs;
              packages = deps;
              shellHook = ''
                export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath libs}:$LD_LIBRARY_PATH"
                export EXTRA_CMAKE_FLAGS="-DGGML_CUDA=OFF -DGGML_BLAS=ON -DGGML_NATIVE=ON"
                export OPENSSL_CRYPTO_LIBRARY="${pkgs.openssl}/lib"
                export OPENSSL_INCLUDE_DIR="${pkgs.openssl}/include"
                echo "Devshell activated."
              '';
            };
        };
    };
}
