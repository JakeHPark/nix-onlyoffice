{
  description = "Get OnlyOffice working properly with Nix.";

  outputs =
    { ... }:
    let
      overlay = final: prev: { microsoft-fonts = final.callPackage ./pkgs/microsoft-fonts { }; };
    in
    {
      overlays.default = overlay;
      overlay = overlay;
      nixosModules.onlyoffice = import ./module.nix;
    };
}
