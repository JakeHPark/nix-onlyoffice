{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.onlyoffice;

  fontPackages =
    if cfg.copyFonts.fontPackages == null then
      config.fonts.packages or [ ]
    else
      cfg.copyFonts.fontPackages;

  fontHash = builtins.hashString "sha256" (lib.concatStringsSep "\n" (map toString fontPackages));
in
{
  options.programs.onlyoffice = {
    enable = lib.mkEnableOption "Get OnlyOffice working with Nix.";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = pkgs.onlyoffice-desktopeditors;
      defaultText = lib.literalExpression "pkgs.onlyoffice-desktopeditors";
      example = lib.literalExpression "null";
      description = ''
        OnlyOffice package to install, or null to not install any package.
      '';
    };

    gstreamer = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to install GStreamer plugins and expose GST_PLUGIN_SYSTEM_PATH_1_0.";
      };

      plugins = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = with pkgs.gst_all_1; [
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
          gst-vaapi
        ];
        defaultText = lib.literalExpression ''
          with pkgs.gst_all_1; [
            gst-plugins-base
            gst-plugins-good
            gst-plugins-bad
            gst-plugins-ugly
            gst-libav
            gst-vaapi
          ]
        '';
        description = "GStreamer plugins exposed to OnlyOffice.";
      };
    };

    copyFonts = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to copy configured fonts into ~/.local/share/fonts for OnlyOffice.";
      };

      fontPackages = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.package);
        default = null;
        description = ''
          Font packages to copy. If null, uses config.fonts.packages from the host system.
        '';
      };

      relativeTargetDir = lib.mkOption {
        type = lib.types.str;
        default = ".local/share/fonts/nix-onlyoffice";
        description = "Target directory relative to the user's home directory.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        environment.systemPackages = lib.optional (cfg.package != null) cfg.package;
      }

      (lib.mkIf cfg.gstreamer.enable {
        environment.systemPackages = cfg.gstreamer.plugins ++ [ pkgs.gst_all_1.gstreamer ];

        # OnlyOffice needs this to play videos.
        # See: http://wiki.nixos.org/wiki/GStreamer#Troubleshooting
        environment.variables.GST_PLUGIN_SYSTEM_PATH_1_0 =
          lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0"
            cfg.gstreamer.plugins;
      })

      (lib.mkIf cfg.copyFonts.enable {
        # OnlyOffice has trouble with symlinks.
        # See: https://github.com/NixOS/nixpkgs/issues/373521#issuecomment-2588283507
        system.userActivationScripts.copy-onlyoffice-fonts.text = ''
          dst="$HOME"/${lib.escapeShellArg cfg.copyFonts.relativeTargetDir}
          hash="$dst/.hash"

          # No need to copy gigabytes every time.
          if [ -f "$hash" ] && [ "$(< "$hash")" = "${fontHash}" ]; then
            exit 0
          fi

          ${pkgs.coreutils}/bin/rm -rf "$dst"
          ${pkgs.coreutils}/bin/mkdir -p "$dst"

          for pkg in ${lib.escapeShellArgs (map toString fontPackages)}; do
            [ -d "$pkg/share/fonts" ] || continue

            ${pkgs.findutils}/bin/find "$pkg/share/fonts" -type f \
              \( -iname '*.ttf' -o -iname '*.otf' -o -iname '*.ttc' -o -iname '*.otc' \) \
              -print0 |
              while IFS= read -r -d "" font; do
                rel="''${font#$pkg/share/fonts/}"
                ${pkgs.coreutils}/bin/install -Dm644 "$font" "$dst/$(${pkgs.coreutils}/bin/basename "$pkg")/$rel"
              done
          done

          printf '%s' "${fontHash}" > "$hash"
          ${pkgs.coreutils}/bin/chmod -R u+rwX,go+rX "$dst"

          ${pkgs.fontconfig}/bin/fc-cache -f "$HOME/.local/share/fonts"
        '';
      })
    ]
  );
}
