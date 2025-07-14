{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.modules.starship;
in {
  options.modules.starship = {
    enable = mkEnableOption "starship prompt";

    package = mkOption {
      type = types.package;
      default = pkgs.starship;
      defaultText = literalExpression "pkgs.starship";
      description = "starship package to use.";
    };

    # extraConfig = mkOption {
    #   default = "";
    #   example = ''
    #     foo bar
    #   '';
    #   type = types.lines;
    #   description = ''
    #     Extra settings for starship.
    #   '';
    # };
  };

  config = mkIf cfg.enable {
    programs.starship = {
      enable = true;
      package = cfg.package;
      # extraConfig = cfg.extraConfig;
    };
  };
}
