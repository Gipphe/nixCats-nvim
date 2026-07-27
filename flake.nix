{
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    wrappers = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    plugins-lze = {
      url = "github:BirdeeHub/lze";
      flake = false;
    };
    plugins-lzextras = {
      url = "github:BirdeeHub/lzextras";
      flake = false;
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      wrappers,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];
      module = lib.modules.importApply ./module.nix inputs;
      neovimModule = {
        imports = [ module ];
        cats = baseCats;
        # specs = lib.mapAttrs (_: enabled: { inherit enabled; }) baseCats;
      };
      droidModule = {
        imports = [ module ];
        cats = droidCats;
      };
      neovimWrapper = wrappers.lib.evalModule neovimModule;
      droidWrapper = wrappers.lib.evalModule droidModule;
      baseCats = {
        lsp = true;
        rich_ui = true;
        rich_editor = true;
        narrow_screen = false;

        bash = true;
        docker = false;
        elm = false;
        fish = true;
        go = false;
        haskell = true;
        html = true;
        js = true;
        lua = true;
        markdown = true;
        nix = true;
        powershell = true;
        python = true;
        qml = false;
        rust = true;
        sql = true;
        terraform = true;
        ts = true;
        xml = false;
        yaml = true;
        yuck = true;
      };
      droidCats = baseCats // {
        lsp = false;
        rich_ui = false;
        rich_editor = false;
        narrow_screen = true;

        bash = false;
        docker = false;
        elm = false;
        fish = false;
        go = false;
        haskell = false;
        html = false;
        js = false;
        lua = false;
        markdown = true;
        nix = false;
        powershell = false;
        python = false;
        qml = false;
        rust = false;
        sql = false;
        terraform = false;
        ts = false;
        xml = false;
        yaml = true;
        yuck = false;
      };
    in
    {
      wrapperModules = {
        neovim = neovimWrapper;
        droid = droidWrapper;
        default = self.wrapperModules.neovim;
      };
      wrappers = {
        neovim = neovimWrapper.config;
        droid = droidWrapper.config;
        default = self.wrappers.neovim;
      };
      overlays = {
        neovim = final: prev: { neovim = self.wrappers.neovim.wrap { pkgs = final; }; };
        droid = final: prev: { neovim = self.wrappers.droid.wrap { pkgs = final; }; };
        default = self.overlays.neovim;
      };
      legacyPackages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          vimPlugins = {
            marp-nvim = pkgs.vimUtils.buildVimPlugin {
              pname = "marp-nvim";
              version = "2025-04-02";
              src = pkgs.fetchFromGitHub {
                owner = "aca";
                repo = "marp.nvim";
                rev = "58d9544d0fa2d78b538e2e2a9b4c018228af0bfe";
                hash = "sha256-aVQsE3aQRH0t7FRtOYlc4+sqcycpa0VBGrww2anEJmA=";
              };
            };
            pnpm-nvim = pkgs.vimUtils.buildVimPlugin {
              pname = "pnpm.nvim";
              version = "2025-04-02";
              src = pkgs.fetchFromGitHub {
                owner = "lukahartwig";
                repo = "pnpm.nvim";
                rev = "b44002c8da2ef68a023ff2c3fa2c454c6c7fa279";
                hash = "sha256-iJ7f4+nB04rlkLr/faCrBUsbgiRT7f9IDQMM0R6xT9M=";
              };
            };
            # TODO: Use upstream package once it is updated to include the
            # license, and thus is no longer considered "non-free".
            nvim-highlight-colors = pkgs.vimUtils.buildVimPlugin {
              pname = "nvim-highlight-colors";
              version = "2026-05-07";
              src = pkgs.fetchFromGitHub {
                owner = "brenoprata10";
                repo = "nvim-highlight-colors";
                rev = "e4c7af0211866162d999ce0bdd6a029302e19139";
                hash = "sha256-4tkehMJpMs/CrQrCFqy+4G9uQei9mAoQlwvxuYtu7z8=";
              };
              nvimSkipModules = [
                "nvim-highlight-colors.color.converters_spec"
                "nvim-highlight-colors.color.patterns_spec"
                "nvim-highlight-colors.color.utils_spec"
                "nvim-highlight-colors.buffer_utils_spec"
                "nvim-highlight-colors.utils_spec"
              ];
            };
          };
        }
      );
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          neovim = self.wrappers.neovim.wrap { inherit pkgs; };
          droid = self.wrappers.droid.wrap { inherit pkgs; };
          default = self.packages.${system}.neovim;
          prettier-with-plugins = pkgs.callPackage ./packages/prettier-with-plugins.nix { };
        }
      );
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [ self.packages.${system}.neovim ];
          };
        }
      );
      checks = forAllSystems (
        system: self.packages.${system} // self.legacyPackages.${system}.vimPlugins
      );
      nixosModules = {
        neovim = wrappers.lib.getInstallModule {
          name = "neovim";
          value = neovimModule;
        };
        droid = wrappers.lib.getInstallModule {
          name = "neovim";
          value = droidModule;
        };
        default = self.nixosModules.neovim;
      };
      homeModules = {
        neovim = self.nixosModules.neovim;
        droid = self.nixosModules.droid;
        default = self.homeModules.neovim;
      };
    };
}
