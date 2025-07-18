{
  description = "Zeit, erfassen. A command line tool for tracking time spent on tasks & projects.";

  inputs.nixpkgs.url = "nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {

      packages = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.buildGoModule {
            pname = "zeit";
            inherit version;
            src = ./.;
            vendorHash = "sha256-fQGaC8WPirncrvJ+7use1ht6wrXBuWeoE2azu0QXtGg=";
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [ go gopls gotools go-tools ];
          };
        });

      nixosModules = {
        default = { config, lib, pkgs, ... }: {
          options.programs.zeit = {
            enable = lib.mkEnableOption "zeit";
            
            package = lib.mkOption {
              type = lib.types.package;
              description = "The zeit package to use.";
            };

            database = lib.mkOption {
              type = lib.types.str;
              default = "/var/lib/zeit/zeit.db";
              description = "The location of the zeit database.";
            };
          };

          config = lib.mkIf config.programs.zeit.enable {
            environment.systemPackages = [ 
              (pkgs.writeShellScriptBin "zeit" ''
                export ZEIT_DB="${config.programs.zeit.database}"
                exec ${config.programs.zeit.package}/bin/zeit "$@"
              '')
            ];
          };
        };
      };
    };
}
