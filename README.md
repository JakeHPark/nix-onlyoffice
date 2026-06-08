# Nix OnlyOffice

OnlyOffice is better than LibreOffice for Microsoft compatibility, and it also has a prettier interface, but there are some issues that need to be resolved before you can get it working smoothly. First, add this repository as an input to your flake:

```nix
{
  # ...
  inputs = {
    # ...
    nix-onlyoffice = {
      url = "github:JakeHPark/nix-onlyoffice";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ...
  };
  # ...
}
```

Then apply the overlay:

```nix
{ inputs, ... }: {
  # ...
  (
    { ... }:
    {
      nixpkgs.overlays = [
        inputs.nix-onlyoffice.overlays.default
        # ...
      ];
    }
  )

  ./configuration.nix

  nix-onlyoffice.nixosModules.onlyoffice
  # ...
}
```

Then in your `configuration.nix`:

```nix
programs.onlyoffice.enable = true;

fonts.packages = with pkgs; [
  # nix-onlyoffice comes with Microsoft fonts like Wingdings.
  # This renders `corefonts` and `vista-fonts` redundant.
  microsoft-fonts
  # ...
];
```

Without `microsoft-fonts`, a lot of symbols and text won't display properly. The other default options are:

```nix
programs.onlyoffice = {
  # This can be set to `null` to not install any package.
  package = pkgs.onlyoffice-desktopeditors;

  gstreamer = {
    # Whether to install GStreamer plugins and expose `GST_PLUGIN_SYSTEM_PATH_1_0`.
    enable = true;

    plugins = with pkgs.gst_all_1; [
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-libav
      gst-vaapi
    ];
  };

  copyFonts = {
    # Whether to copy configured fonts into `~/.local/share/fonts`.
    enable = true;

    # The font packages to copy. If `null`, it refers to `config.fonts.packages`.
    fontPackages = null;

    # Where to copy the font packages to.
    relativeTargetDir = ".local/share/fonts/nix-onlyoffice";
  };
};
```

In particular, the GStreamer plugins are [necessary](http://wiki.nixos.org/wiki/GStreamer#Troubleshooting) for integrated video playing, and the font copying is [necessary](https://github.com/NixOS/nixpkgs/issues/373521#issuecomment-2588283507) for OnlyOffice to recognise them at all.
