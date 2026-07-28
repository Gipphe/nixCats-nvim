{
  lib,
  symlinkJoin,
  vimPlugins,
}:
let
  inherit (builtins) isString filter;
  generateQueries =
    { name, value }:
    let
      lang = name;
      parserPkg = value;
      rev =
        if isString (parserPkg.src.rev or null) then
          parserPkg.src.rev
        else if isString (parserPkg.version or null) then
          parserPkg.version
        else
          "main";
    in
    symlinkJoin {
      name = "${lang}-parser-and-queries";
      paths = [ parserPkg ];
      postBuild = ''
        mkdir -p "$out/queries"
        mkdir -p "$out/parser-info"
        echo '${rev}' > "$out/parser-info/${lang}.revision"
        ln -s '${vimPlugins.nvim-treesitter}/runtime/queries/${lang}' "$out/queries/${lang}"
      '';
    };
in
symlinkJoin {
  name = "treesitter-parsers-and-queries";
  paths = map generateQueries (
    filter ({ name, value }: isString name && lib.isDerivation value) (
      lib.attrsToList vimPlugins.nvim-treesitter-parsers
    )
  );
}
