return {
  enabled = nixInfo(false, 'settings', 'cats', 'nix'),
  settings = {
    nixd = {
      nixpkgs = {
        expr = nixInfo('import <nixpkgs> {}', 'settings', 'nixd', 'nixpkgs', 'expr'),
      },
      formatting = {
        command = { 'nixfmt' },
      },
      options = nixInfo({}, 'settings', 'nixd', 'options'),
    },
  },
}
