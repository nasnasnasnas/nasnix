{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.wifiman;
in {
  options.modules.wifiman = {
    enable = mkEnableOption "wifiman";

    # extraConfig = mkOption {
    #   default = "";
    #   example = ''
    #     foo bar
    #   '';
    #   type = types.lines;
    #   description = ''
    #     Extra settings for fd.
    #   '';
    # };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (let
         wifimanPkg = pkgs.stdenv.mkDerivation rec {
           pname = "wifiman";
           version = "1.2.7";

           src = pkgs.fetchurl {
             url = "https://desktop.ea.wifiman.com/wifiman-desktop-${version}-amd64.deb";
             hash = "sha256-aHGtifGEyNfA/ixDoxzifyVJBmbxdogTlhxR5uuoZNQ=";
           };

           nativeBuildInputs = [
             pkgs.dpkg
           ];

           unpackPhase = "true";

           installPhase = ''
             mkdir -p $out
             dpkg -x $src $out
             if [ -d "$out/usr" ]; then
               cp -av $out/usr/* $out
               rm -rf $out/usr
             fi
           '';

           meta = with lib; {
             homepage = "https://ui.com";
             description = "wifiman (extracted payload)";
             platforms = platforms.linux;
           };
         };
         wifimanWrapper = pkgs.writeShellScriptBin "wifiman-wrapper" ''
           set -euo pipefail
           DAEMON="${wifimanPkg}/lib/wifiman-desktop/wifiman-desktopd"
           APP="${wifimanPkg}/bin/wifiman-desktop"

           # Start the daemon if not already running
           if [ -x "$DAEMON" ]; then
             if ! pgrep -f "$DAEMON" >/dev/null 2>&1; then
               "$DAEMON" &
               DPID=$!
               cleanup() { kill "$DPID" 2>/dev/null || true; }
               trap cleanup EXIT INT TERM
             fi
           fi

           exec "$APP" "$@"
         '';
       in pkgs.buildFHSEnv {
         name = "wifiman";
         targetPkgs = pkgs: with pkgs; [
           glib
           openssl
           webkitgtk_4_1
           gtk3
           gcc-unwrapped
           pango
           gdk-pixbuf
           cairo
           libsoup_3
           xdg-utils
           desktop-file-utils
           libayatana-appindicator
           libdbusmenu-gtk3
           wirelesstools
           iw
         ];
         runScript = "${wifimanWrapper}/bin/wifiman-wrapper";
       })
    ];
  };
}
