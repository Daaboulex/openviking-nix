# NixOS module for running the OpenViking server as a systemd service
flake:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.openviking;
in
{
  _class = "nixos";
  options.services.openviking = {
    enable = lib.mkEnableOption "OpenViking context database server";

    package = lib.mkOption {
      type = lib.types.package;
      default = flake.packages.${pkgs.stdenv.hostPlatform.system}.openviking;
      defaultText = lib.literalExpression "flake.packages.\${pkgs.stdenv.hostPlatform.system}.openviking";
      description = "The OpenViking package to use";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 1933;
      description = "Port for the OpenViking server to listen on";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Host address for the OpenViking server to bind to";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/openviking";
      description = "Data directory for OpenViking storage and workspace";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Path to ov.conf configuration file.
        If null, the server looks for config at dataDir/ov.conf.
        The config file specifies embedding model endpoint, LLM endpoint,
        and workspace path. See OpenViking docs for format.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the OpenViking server port";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.openviking = {
      description = "OpenViking Context Database Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      environment = {
        OPENVIKING_CONFIG_FILE =
          if cfg.configFile != null then toString cfg.configFile else "${cfg.dataDir}/ov.conf";
        OPENVIKING_HOST = cfg.host;
        OPENVIKING_PORT = toString cfg.port;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/openviking-server";
        WorkingDirectory = cfg.dataDir;
        StateDirectory = "openviking";
        DynamicUser = true;
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadWritePaths = [ cfg.dataDir ];
        CapabilityBoundingSet = "";
        SystemCallArchitectures = "native";
      };
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
