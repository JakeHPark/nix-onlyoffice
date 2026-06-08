{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "microsoft-fonts";
  version = "1.0";

  src = fetchFromGitHub {
    owner = "pjobson";
    repo = "Microsoft-365-Fonts";
    rev = "7c8579f74169d08ddcbc0420f7ce74acccf172c2";
    hash = "sha256-D4wGWex6e9eyyHCfDj/7C8Gfc66jV7NLy3JWLFQVBpg=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    find . -type f -iname '*.ttf' -print0 |
      while IFS= read -r -d "" font; do
        install -Dm644 "$font" -t "$out/share/fonts/truetype/"
      done

    runHook postInstall
  '';

  meta = {
    description = "Microsoft fonts. Renders corefonts and vista-fonts redundant.";
    homepage = "https://github.com/pjobson/Microsoft-365-Fonts";
    license = with lib.licenses; [ unfree ];
    platforms = lib.platforms.all;
  };
})
