{
  lib,
  stdenv,
  fetchurl,
  ...
}:

let
  version = "0.1.191";

  # Map Nix system strings to GitHub asset names and hashes
  platforms = {
    "aarch64-darwin" = {
      name = "nb-arm64-apple-darwin.tar.gz";
      sha256 = "12e1a2c4764878e9735112595bc60262607cef54da6df321621e0149daf9f4c6";
    };
    "x86_64-darwin" = {
      name = "nb-x86_64-apple-darwin.tar.gz";
      sha256 = "67af5cb2ed80cd7247dc175f55a7012e944cde265ed2f91b2389a984484209e9";
    };
    "x86_64-linux" = {
      name = "nb-x86_64-linux.tar.gz";
      sha256 = "5d91f2b4a2c60c796a833e6fb7930697e13f46e961baddbe6e3c5c3220699dd4";
    };
    "aarch64-linux" = {
      name = "nb-arm64-linux.tar.gz";
      sha256 = "0792580b850de9607ccf209cf0c0d4720fc33103ad480dcf85549d0c874e86e2";
    };
  };

  plat =
    platforms.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "nanobrew";
  inherit version;

  src = fetchurl {
    url = "https://github.com/justrach/nanobrew/releases/download/v${version}/${plat.name}";
    inherit (plat) sha256;
  };

  sourceRoot = ".";

  installPhase = ''
    install -Dm755 nb $out/bin/nb
  '';

  meta = with lib; {
    description = "Fast Homebrew alternative written in Zig";
    homepage = "https://github.com/justrach/nanobrew";
    license = licenses.asl20;
    mainProgram = "nb";
    platforms = builtins.attrNames platforms;
  };
}
