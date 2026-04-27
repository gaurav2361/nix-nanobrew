{
  lib,
  stdenv,
  zig,
  nanobrew-src,
  ...
}:

stdenv.mkDerivation {
  pname = "nanobrew";
  version = "0.1.192";

  src = nanobrew-src;

  patches = [
    ./fix-migrate-metadata.patch
  ];

  nativeBuildInputs = [ zig ];

  buildPhase = ''
    export ZIG_GLOBAL_CACHE_DIR=$TMPDIR/zig-cache
    zig build -Doptimize=ReleaseFast
  '';

  installPhase = ''
    install -Dm755 zig-out/bin/nb $out/bin/nb
  '';

  meta = with lib; {
    description = "Fast Homebrew alternative written in Zig";
    homepage = "https://github.com/justrach/nanobrew";
    license = licenses.asl20;
    mainProgram = "nb";
    platforms = platforms.darwin ++ platforms.linux;
  };
}
