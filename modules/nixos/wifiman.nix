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
      (pkgs.stdenv.mkDerivation rec {
         pname = "wifiman";
         version = "1.1.3";

         src = pkgs.fetchurl {
           url = "https://desktop.wifiman.com/wifiman-desktop-${version}-amd64.deb";
           hash = "sha256-y//hyqymtgEdrKZt3milTb4pp+TDEDQf6RehYgDnhzA=";
         };

         nativeBuildInputs = [
           pkgs.autoPatchelfHook
           pkgs.dpkg
         ];

         buildInputs = [
          pkgs.glib
          pkgs.openssl
          pkgs.webkitgtk_4_0
          pkgs.gtk3
          pkgs.gcc-unwrapped
         ];


         unpackPhase = "true";

         installPhase = ''
             mkdir -p $out
             dpkg -x $src $out
             cp -av $out/usr/* $out
             rm -rf $out/usr
           '';

         meta = with lib; {
           homepage = "https://ui.com";
           description = "wifiman";
           platforms = platforms.linux;
         };
       })
    ];
  };
}
