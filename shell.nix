let
  nixpkgs = import <nixpkgs> { };
in
  with nixpkgs;
  stdenv.mkDerivation {
    name = "game-clones-env";
    buildInputs = [
      zig
      git
      pkgconfig
      openssl
      gcc
      libGL
      xorg.libX11 xorg.libXcursor xorg.libXrandr xorg.libXi xorg.libxcb
      alsaLib
      cmake gnumake
      freetype
      python3
      expat
      SDL2 SDL2_image SDL2_ttf SDL_gpu
      ];
    shellHook = ''
      export RUST_BACKTRACE=1
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${xorg.libX11}/lib
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${xorg.libXcursor}/lib
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${xorg.libXrandr}/lib
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${xorg.libXi}/lib
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${libGL}/lib
      export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:${xorg.libxcb}/lib
    '';
  }
