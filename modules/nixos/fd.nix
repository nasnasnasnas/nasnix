{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.fd;
in {
  options.modules.fd = {
    enable = mkEnableOption "fd file search";

    package = mkOption {
      type = types.package;
      default = pkgs.fd;
      defaultText = literalExpression "pkgs.fd";
      description = "fd package to use.";
    };

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
    environment.systemPackages = [cfg.package];
  };
}
