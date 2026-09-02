local util = require 'util'
local keys = require 'keygroups'

return {
  {
    'haskell-tools.nvim',
    pack = {
      src = util.gh 'mrcjkb/haskell-tools.nvim',
      version = vim.version.range '^10',
    },
    enabled = nixInfo(false, 'settings', 'cats', 'lsp') and nixInfo(false, 'settings', 'cats', 'haskell'),
    lazy = false,
    after = function()
      local hls_fallback = nixInfo(nil, 'info', 'haskell', 'fallback', 'haskell-langauge-server')
      local fourmolu_fallback = nixInfo(nil, 'info', 'haskell', 'fallback', 'fourmolu')

      for fb in pairs { hls_fallback, fourmolu_fallback } do
        if fb ~= nil then
          vim.env.PATH = vim.env.PATH .. ':' .. fb
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('haskell-tools', { clear = true }),
        pattern = { 'haskell' },
        callback = function(buffer)
          local ht = require 'haskell-tools'
          local lmap = function(mode, l, r, desc)
            vim.keymap.set(mode, l, r, {
              noremap = true,
              silent = true,
              buffer = buffer.buf,
              desc = desc,
            })
          end
          local cmap = function(mode, l, r, desc)
            lmap(mode, keys.key.code(l), r, desc)
          end
          cmap('n', 'l', vim.lsp.codelens.run, 'Run codelens')
          cmap('n', 'hs', ht.hoogle.hoogle_signature, 'Hoogle search type signature under cursor')
          cmap('n', 'ea', ht.lsp.buf_eval_all, 'Evaluate all code snippets')
          cmap('n', 'pr', ht.repl.toggle, 'Toggle GHCi repl for the current package')
          cmap('n', 'pR', function()
            ht.repl.toggle(vim.api.nvim_buf_get_name(0))
          end, 'Toggle GHCi repl for current buffer')
          cmap('n', 'pq', ht.repl.quit, 'Close GHCi repl')
        end,
      })
    end,
  },

  {
    'otter.nvim',
    pack = {
      src = util.gh 'jmbuhr/otter.nvim',
    },
    enabled = nixInfo(false, 'settings', 'cats', 'lsp'),
    after = function()
      require('otter').setup {
        handle_leading_whitespace = true,
      }
    end,
  },

  {
    'yuck.nvim',
    pack = {
      src = util.gh 'elkowar/yuck.vim',
    },
    enabled = nixInfo(false, 'settings', 'cats', 'yuck'),
    ft = { 'yuck' },
  },

  {
    'pnpm.nvim',
    pack = {
      src = util.gh 'lukahartwig/pnpm.nvim',
    },
    enabled = nixInfo(false, 'settings', 'cats', 'js') or nixInfo(false, 'settings', 'cats', 'ts'),
    ft = { 'js', 'ts', 'tsx', 'jsx' },
  },

  {
    'vim-go',
    pack = {
      src = util.gh 'fatih/vim-go',
    },
    enabled = nixInfo(false, 'settings', 'cats', 'go'),
    ft = { 'go', 'html', 'gotmpl', 'gohtmltmpl' },
    after = function()
      vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufWinEnter', 'BufWritePre' }, {
        group = vim.api.nvim_create_augroup('gotmpl_syntax', { clear = true }),
        pattern = '*.gohtml,*.gotmpl,*.html',
        callback = function(event)
          if vim.fn.search('{{.\\+}}', 'nw') ~= 0 then
            vim.api.nvim_set_option_value('filetype', 'gohtmltmpl', { buf = event.buf })
          end
        end,
      })
    end,
  },

  {
    'mason.nvim',
    pack = {
      src = util.gh 'williamboman/mason.nvim',
    },
    -- NOTE: only enable mason if nix wasn't involved. because we will be using
    -- nix to download things instead.
    enabled = not nixInfo.isNix,
    priority = 100,
    on_plugin = { 'nvim-lspconfig' },
    after = function()
      require('mason').setup {}
    end,
  },

  {
    'mason-lspconfig.nvim',
    pack = {
      src = util.gh 'williamboman/mason-lspconfig.nvim',
    },
    -- NOTE: only enable mason if nix wasn't involved.
    -- because we will be using nix to download things instead.
    enabled = not nixInfo.isNix,
  },

  {
    'mason-tool-installer.nvim',
    pack = {
      src = util.gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
    -- NOTE: only enable mason if nix wasn't involved.
    -- because we will be using nix to download things instead.
    enabled = not nixInfo.isNix,
  },
  -- Useful status updates for LSP.
  -- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
  {
    'fidget.nvim',
    enabled = nixInfo(false, 'settings', 'cats', 'lsp'),
    pack = {
      src = util.gh 'j-hui/fidget.nvim',
    },
    after = function()
      require('fidget').setup {}
    end,
  },

  {
    'nvim-lspconfig',
    pack = {
      src = util.gh 'neovim/nvim-lspconfig',
    },
    enabled = nixInfo(false, 'settings', 'cats', 'lsp'),
    after = function()
      local opts = {
        category_servers = {
          bash = 'bashls',
          docker = 'dockerls',
          elm = 'elmls',
          fish = 'fish_lsp',
          go = 'gopls',
          html = 'html',
          js = { 'eslint', 'tailwindcss' },
          json = 'jsonls',
          lua = 'lua_ls',
          markdown = 'marksman',
          nix = { nixInfo.isNix and 'nixd' or 'nil' },
          nushell = 'nushell',
          powershell = 'powershell_es',
          python = 'ruff',
          qml = 'qmlls',
          rust = 'rust_analyzer',
          sql = 'sqls',
          terraform = 'terraformls',
          ts = { 'eslint', 'tailwindcss', 'ts_ls', 'denols' },
          xml = 'lemminx',
          yaml = 'yamlls',
        },
      }
      -- Remove default keybindings for LSP
      vim.keymap.del('n', 'grn')
      vim.keymap.del('n', 'gra')
      vim.keymap.del('n', 'grr')
      vim.keymap.del('n', 'gri')
      vim.keymap.del('n', 'grt')
      vim.keymap.del('n', 'gO')
      vim.keymap.del('i', '<C-S>')

      local log_file_path = vim.lsp.log.get_filename()

      -- Keep the LSP log from growing unbounded: if it's over 500 KB on
      -- startup, trim it down to the most recent 500 KB.
      do
        local uv = vim.uv or vim.loop
        local max_size = 500 * 1024
        local stat = uv.fs_stat(log_file_path)
        if stat and stat.size > max_size then
          local fd = uv.fs_open(log_file_path, 'r+', 438)
          if fd then
            local data = uv.fs_read(fd, max_size, stat.size - max_size)
            if data then
              uv.fs_write(fd, data, 0)
              uv.fs_ftruncate(fd, max_size)
            end
            uv.fs_close(fd)
          end
        end
      end

      vim.api.nvim_create_user_command('LspInfo', ':checkhealth vim.lsp', { desc = 'Alias to `:checkhealth vim.lsp`' })
      vim.api.nvim_create_user_command('LspLog', function()
        vim.cmd.edit(log_file_path)
      end, {
        desc = 'Open the LSP log',
      })
      local complete_client = function(arg)
        return vim
          .iter(vim.lsp.get_clients())
          :map(function(client)
            return client.name
          end)
          :filter(function(name)
            return name:sub(1, #arg) == arg
          end)
          :totable()
      end

      local complete_config = function(_) end

      vim.api.nvim_create_user_command('LspStart', function(info)
        local servers = info.fargs

        -- Default to enabling all servers matching the filetype of the current buffer.
        -- This assumes that they've been explicitly configured through `vim.lsp.config`,
        -- otherwise they won't be present in the private `vim.lsp.config._configs` table.
        if #servers == 0 then
          local filetype = vim.bo.filetype
          ---@diagnostic disable-next-line: invisible
          for name, _ in pairs(vim.lsp.config._configs) do
            local filetypes = vim.lsp.config[name].filetypes
            if filetypes and vim.tbl_contains(filetypes, filetype) then
              table.insert(servers, name)
            end
          end
        end

        vim.lsp.enable(servers)
      end, {
        desc = 'Enable and launch a language server',
        nargs = '?',
        complete = complete_config,
      })

      vim.api.nvim_create_user_command('LspRestart', function(info)
        local client_names = info.fargs

        -- Default to restarting all active servers
        if #client_names == 0 then
          client_names = vim
            .iter(vim.lsp.get_clients())
            :map(function(client)
              return client.name
            end)
            :totable()
        end

        for name in vim.iter(client_names) do
          if vim.lsp.config[name] == nil then
            vim.notify(("Invalid server name '%s'"):format(name))
          else
            vim.lsp.enable(name, false)
            if info.bang then
              vim.iter(vim.lsp.get_clients { name = name }):each(function(client)
                client:stop(true)
              end)
            end
          end
        end

        local timer = assert(vim.uv.new_timer())
        timer:start(500, 0, function()
          for name in vim.iter(client_names) do
            vim.schedule_wrap(vim.lsp.enable)(name)
          end
          timer:close()
        end)
      end, {
        desc = 'Restart the given client',
        nargs = '?',
        bang = true,
        complete = complete_client,
      })

      vim.api.nvim_create_user_command('LspStop', function(info)
        local client_names = info.fargs

        -- Default to disabling all servers on current buffer
        if #client_names == 0 then
          client_names = vim
            .iter(vim.lsp.get_clients())
            :map(function(client)
              return client.name
            end)
            :totable()
        end

        for name in vim.iter(client_names) do
          if vim.lsp.config[name] == nil then
            vim.notify(("Invalid server name '%s'"):format(name))
          else
            vim.lsp.enable(name, false)
            if info.bang then
              vim.iter(vim.lsp.get_clients { name = name }):each(function(client)
                client:stop(true)
              end)
            end
          end
        end
      end, {
        desc = 'Disable and stop the given client',
        nargs = '?',
        bang = true,
        complete = complete_client,
      })

      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
        callback = function(event)
          ---@param l string
          ---@param func string|function
          ---@param desc string
          local map = function(l, func, desc)
            vim.keymap.set('n', l, func, { buffer = event.buf, desc = desc })
          end

          -- Open LSP info
          map(keys.key.code 'l', '<cmd>LspInfo<cr>', 'Lsp info')
          map(keys.key.code 'L', '<cmd>LspLog<cr>', 'Lsp log')

          -- Jump to the definition of the word under your cursor.
          -- This is where a variable was first declared, or where a function is defined, etc.
          -- To jump back, press <C-t>.
          map(keys.key.goto 'd', function()
            require('snacks').picker.lsp_definitions { reuse_win = true }
          end, 'Goto definition')

          map(keys.key.goto 'r', function()
            require('snacks').picker.lsp_references()
          end, 'Goto references')

          map(keys.key.goto 'D', function()
            vim.lsp.buf.declaration()
          end, 'Goto declaration')

          map(keys.key.goto 'I', function()
            require('snacks').picker.lsp_implementations { reuse_win = true }
          end, 'Goto implementation')

          map(keys.key.goto 'y', function()
            require('snacks').picker.lsp_type_definitions { reuse_win = true }
          end, 'Goto type definition')

          -- Opens a popup that displays documentation about the word under your cursor
          --  See `:help K` for why this keymap.
          map('K', function()
            vim.lsp.buf.hover { border = 'rounded' }
          end, 'Hover documentation')

          map(keys.key.goto 'K', function()
            vim.lsp.buf.signature_help { border = 'rounded' }
          end, 'Signature help')

          vim.keymap.set('i', '<C-k>', function()
            vim.lsp.buf.signature_help { border = 'rounded' }
          end, { desc = 'Signature help', buffer = event.buf })

          vim.keymap.set({ 'n', 'v' }, keys.key.code 'a', function()
            vim.lsp.buf.code_action { border = 'rounded' }
          end, { desc = 'Code action', buffer = event.buf })

          vim.keymap.set({ 'n', 'v' }, keys.key.code 'c', vim.lsp.codelens.run, { desc = 'Run codelens', buffer = event.buf })
          vim.keymap.set('n', keys.key.code 'C', function()
            vim.lsp.codelens.enable(true)
          end, { desc = 'Refresh & display codelens', buffer = event.buf })
          vim.keymap.set('n', keys.key.code 'A', function()
            vim.lsp.buf.code_action {
              context = {
                only = { 'source' },
                diagnostics = {},
              },
              border = 'rounded',
            }
          end, { desc = 'Source action', buffer = event.buf })

          vim.keymap.set('n', keys.key.code 'r', vim.lsp.buf.rename, { desc = 'Rename', buffer = event.buf })

          -- Fuzzy find all the symbols in your current document.
          --  Symbols are things like variables, functions, types, etc.
          -- vim.keymap.set('n', '<leader>cy', require('snacks').picker.lsp_document_symbols, { desc = 'Document symbols', buffer = event.buf })

          -- Fuzzy find all the symbols in your current workspace.
          --  Similar to document symbols, except searches over your entire project.
          -- vim.keymap.set('n', '<leader>cY', require('snacks').picker.lsp_dynamic_workspace_symbols, { desc = '[W]orkspace [S]ymbols', buffer = event.buf })

          -- WARN: This is not Goto Definition, this is Goto Declaration.
          --  For example, in C this would take you to the header.
          map(keys.key.goto 'D', function()
            vim.lsp.buf.declaration { border = 'rounded' }
          end, 'Goto declaration')

          -- The following two autocommands are used to highlight references of the
          -- word under your cursor when your cursor rests there for a little while.
          --    See `:help CursorHold` for information about when this is executed
          --
          -- When you move your cursor, the highlights will be cleared (the second autocommand).
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          -- The following autocommand is used to enable inlay hints in your
          -- code, if the language server you are using supports them
          --
          -- This may be unwanted, since they displace some of your code
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
            map(keys.key.code 'th', function()
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
            end, 'Toggle inlay hints')
          end
        end,
      })

      local severity = vim.diagnostic.severity
      vim.diagnostic.config {
        severity_sort = true,
        float = { border = 'rounded', source = 'if_many' },
        underline = { severity = severity.ERROR },
        signs = vim.g.have_nerd_font and {
          text = {
            [severity.ERROR] = '󰅚 ',
            [severity.WARN] = '󰀪 ',
            [severity.INFO] = '󰋽 ',
            [severity.HINT] = '󰌶 ',
          },
        } or {},
        virtual_text = {
          source = 'if_many',
          spacing = 2,
          format = function(diagnostic)
            local diagnostic_message = {
              [severity.ERROR] = diagnostic.message,
              [severity.WARN] = diagnostic.message,
              [severity.INFO] = diagnostic.message,
              [severity.HINT] = diagnostic.message,
            }
            return diagnostic_message[diagnostic.severity]
          end,
        },
      }

      local capabilities = require('blink.cmp').get_lsp_capabilities()
      vim.lsp.config('*', { capabilities = capabilities })
      ---@type string[]
      local servers = opts.servers or {}

      -- Append servers based on categories
      for cat, srvs in pairs(opts.category_servers) do
        if nixInfo(false, 'settings', 'cats', cat) then
          local srvs_list = {}
          if type(srvs) == 'function' then
            srvs_list = srvs()
          elseif type(srvs) == 'table' then
            srvs_list = srvs
          elseif type(srvs) == 'string' then
            srvs_list = { srvs }
          end
          for _, srv in pairs(srvs_list) do
            servers[#servers + 1] = srv
          end
        end
      end
      servers = vim.fn.uniq(vim.fn.sort(servers)) --[[@as string[] ]]

      -- NOTE: if nix, use vim.lsp instead of mason. You could MAKE it work,
      -- using lspsAndRuntimeDeps and sharedLibraries in nix but don't...
      -- its not worth it. Just add the lsp to lspsAndRuntimeDeps.
      if nixInfo.isNix then
        vim.lsp.enable(servers)
      else
        -- NOTE: and if no nix, do it the normal way

        -- Ensure the servers and tools above are installed
        --  To check the current status of installed tools and/or manually install
        --  other tools, you can run
        --    :Mason
        --
        --  You can press `g?` for help in this menu.
        require('mason').setup()

        -- You can add other tools here that you want Mason to install
        -- for you, so that they are available from within Neovim.
        require('mason-tool-installer').setup { ensure_installed = servers }

        require('mason-lspconfig').setup {
          ensure_installed = {},
          automatic_enable = true,
        }
      end
    end,
  },

  {
    'venv-selector.nvim',
    pack = {
      src = util.gh 'linux-cultist/venv-selector.nvim',
    },
    enabled = nixInfo(false, 'settings', 'cats', 'python'),
    ft = 'python',
    after = function()
      ---@module 'venv-selector'
      ---@type venv-selector.Settings
      local opts = {
        search = {},
        options = {},
      }
      require('venv-selector').setup(opts)
    end,
    keys = {
      {
        lhs = keys.key.code 'v',
        rhs = '<cmd>VenvSelect<cr>',
        desc = 'Select VirtualEnv',
      },
    },
  },
}
