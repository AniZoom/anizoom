{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devenv.url = "github:cachix/devenv";
    flake-root.url = "github:srid/flake-root";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs = inputs@{ flake-parts, nixpkgs, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
        inputs.flake-root.flakeModule
      ];
      systems = nixpkgs.lib.systems.flakeExposed;

      perSystem = { config, self', inputs', pkgs, system, lib, ... }:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowBroken = true;
          };
        in
        let
          libraries = with pkgs; [
            webkitgtk
            gtk3
            cairo
            gdk-pixbuf
            glib-networking
            glib
            dbus
            openssl_3
            librsvg
          ];
          extraPackages = with pkgs; [
            cargo-tauri
            nodePackages.pnpm
          ];
          packages = (with pkgs;  [
            curl
            wget
            pkg-config
            dbus
            openssl_3
            glib
            glib-networking
            gtk3
            libsoup
            webkitgtk
            librsvg
          ]) ++ extraPackages;
          apple_sdk = with pkgs; [
            darwin.apple_sdk.frameworks.Foundation
            darwin.apple_sdk.frameworks.System
            darwin.apple_sdk.frameworks.Carbon
            darwin.apple_sdk.frameworks.Cocoa
            darwin.apple_sdk.frameworks.WebKit
          ];
          darwin_packages = apple_sdk ++ extraPackages;
        in
        {
          devenv.shells.default = {
            name = "anizoom";
            languages.rust = {
              enable = true;
              channel = "nightly";
            };
            packages = if (pkgs.stdenv.isDarwin) then darwin_packages else packages;
            enterShell =
              if (pkgs.stdenv.isDarwin) then ''
                echo $'\e[1;32mWelcom to anizoom project~\e[0m'
              '' else ''
                echo $'\e[1;32mWelcom to anizoom project~\e[0m'
                export LD_LIBRARY_PATH=${pkgs.lib.makeLibraryPath libraries}:$LD_LIBRARY_PATH
                export XDG_DATA_DIRS=${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}:$XDG_DATA_DIRS
                export GIO_MODULE_DIR="${pkgs.glib-networking}/lib/gio/modules/"
              '';
          };
        };
    };
}
