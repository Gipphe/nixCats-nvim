local keys = require 'keygroups'
local util = require 'util'

return {
  {
    'conform.nvim',
    pack = {
      src = util.gh 'stevearc/conform.nvim',
    },
    lazy = false,
    keys = {
      {
        lhs = keys.key.code 'f',
        rhs = function()
          require('conform').format { async = true, lsp_fallback = true }
        end,
        mode = { 'n', 'v' },
        desc = 'Format buffer',
      },
      {
        lhs = keys.key.code 'F',
        rhs = function()
          require('conform').format { formatters = { 'injected' }, timeout_ms = 3000 }
        end,
        mode = { 'n', 'v' },
        desc = 'Format injected langs',
      },
    },
    after = function()
      local prettier = { 'prettierd', 'prettier', stop_after_first = true }
      local category_formatters = {
        markdown = {
          ['markdown.mdx'] = prettier,
          markdown = prettier,
        },
        fish = {
          fish = { 'fish_indent' },
        },
        haskell = {
          haskell = { 'fourmolu', stop_after_first = true },
          cabal = { 'cabal_fmt' },
        },
        html = {
          css = prettier,
          html = prettier,
        },
        js = {
          javascript = prettier,
          javascriptreact = prettier,
        },
        ts = {
          typescript = prettier,
          typescriptreact = prettier,
        },
        json = {
          json = prettier,
          jsonc = prettier,
        },
        lua = {
          lua = { 'stylua' },
        },
        nix = {
          nix = { 'nixfmt' },
        },
        nushell = {
          nu = { 'nufmt' },
        },
        python = {
          python = { 'ruff_format', 'ruff_organize_imports' },
        },
        bash = {
          sh = { 'shfmt' },
        },
        terraform = {
          terraform = { 'tofu_fmt' },
        },
        yaml = {
          yaml = prettier,
        },
      }
      local opts = {
        notify_on_error = true,
        notify_no_formatters = true,
        format_on_save = function(bufnr)
          -- Disable "format_on_save lsp_fallback" for languages that don't
          -- have a well standardized coding style. You can add additional
          -- languages here or re-enable it for the disabled ones.
          local disable_filetypes = { c = true, cpp = true }
          return {
            timeout_ms = 500,
            lsp_fallback = not disable_filetypes[vim.bo[bufnr].filetype],
          }
        end,
        formatters_by_ft = {
          ['*'] = { 'codespell' },
          ['_'] = { 'trim_whitespace' },
        },
        formatters = {
          injected = {
            options = {
              ignore_errors = true,
            },
          },
        },
        format = {
          timeout_ms = 3000,
          async = false,
          quiet = false,
        },
      }

      for cat, formatters in pairs(category_formatters) do
        if nixInfo(true, 'settings', 'cats', cat) then
          opts.formatters_by_ft = vim.tbl_deep_extend('force', {}, opts.formatters_by_ft, formatters)
        end
      end

      require('conform').setup(opts)
    end,
  },
}
