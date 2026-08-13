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

    settings = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
      description = ''
        Declarative configuration for OpenViking (ov.conf).
        If set, a JSON file will be generated and passed to the service.
      '';
    };

    readOnlyPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of read-only paths to allow the service to access (e.g., project directories in /home).";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the OpenViking server port";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "openviking";
      description = "User account under which the OpenViking server runs";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "openviking";
      description = "Group under which the OpenViking server runs";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Extra groups for the OpenViking service (e.g., to access user files).";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = lib.mkIf (cfg.user == "openviking") {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.dataDir;
      createHome = true;
    };

    users.groups.${cfg.group} = lib.mkIf (cfg.group == "openviking") { };

    systemd.services.openviking = {
      description = "OpenViking Context Database Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p ${cfg.dataDir}
        chown ${cfg.user}:${cfg.group} ${cfg.dataDir}
      '';

      environment = {
        OPENVIKING_CONFIG_FILE =
          if cfg.settings != null then
            (pkgs.formats.json { }).generate "ov.conf" cfg.settings
          else if cfg.configFile != null then
            toString cfg.configFile
          else
            "${cfg.dataDir}/ov.conf";
        OPENVIKING_HOST = cfg.host;
        OPENVIKING_PORT = toString cfg.port;
      };

      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/openviking-server";
        WorkingDirectory = cfg.dataDir;
        User = cfg.user;
        Group = cfg.group;
        SupplementaryGroups = cfg.extraGroups;
        Restart = "on-failure";
        RestartSec = 5;

        # Hardening
        ProtectSystem = "strict";
        ProtectHome = lib.mkDefault (if cfg.user == "openviking" then true else "read-only");
        ReadOnlyPaths = cfg.readOnlyPaths;
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
