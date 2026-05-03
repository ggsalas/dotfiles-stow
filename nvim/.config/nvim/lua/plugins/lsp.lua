return {
  -- ======================
  -- MASON
  -- ======================
  {
    "williamboman/mason.nvim",
    lazy = false,
    config = function()
      require("mason").setup()
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "black",
          "isort",
          "stylua",
          "eslint_d",

          -- LSPs
          "clangd",
          "pyright",
          "typescript-language-server",
          "lua-language-server",
          "phpactor",
          "tailwindcss-language-server",
          "css-lsp",
          "cssmodules-language-server",
        },
      })
    end,
  },

  -- ======================
  -- LSP
  -- ======================
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local builtin = require("telescope.builtin")

      -- 🔑 on_attach
      local on_attach = function(_, bufnr)
        local nmap = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = desc and ("LSP: " .. desc) })
        end

        -- Actions
        nmap("<leader>rn", vim.lsp.buf.rename, "Rename")
        nmap("ga", vim.lsp.buf.code_action, "Code Action (quick)")

        -- navigation
        nmap("gd", builtin.lsp_definitions, "Goto Definition")
        nmap("gr", builtin.lsp_references, "Goto References")
        nmap("gi", builtin.lsp_implementations, "Goto Implementation")
        nmap("gD", vim.lsp.buf.declaration, "Goto Declaration")

        -- diagnostics
        local function goto_diag(next)
          return function()
            vim.diagnostic.jump({ count = next and 1 or -1 })
            vim.schedule(function()
              vim.diagnostic.open_float(nil, { focus = false })
            end)
          end
        end

        nmap("]e", goto_diag(true), "Next Error")
        nmap("[e", goto_diag(false), "Prev Error")
        nmap("<leader>e", vim.diagnostic.open_float, "Show Error")

        -- info
        nmap("K", vim.lsp.buf.hover, "Hover")
        nmap("<leader>k", vim.lsp.buf.signature_help, "Signature Help")

        -- extras
        nmap("<leader>D", builtin.lsp_type_definitions, "Type Definition")
        nmap("<leader>ds", builtin.lsp_document_symbols, "Document Symbols")
        nmap("<leader>ws", builtin.lsp_dynamic_workspace_symbols, "Workspace Symbols")
      end

      -- 🔑 capabilities
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local function setup(name, opts)
        opts = opts or {}
        opts.capabilities = capabilities
        opts.on_attach = opts.on_attach or on_attach

        vim.lsp.config(name, opts)
        vim.lsp.enable(name)
      end

      -- ======================
      -- SERVERS
      -- ======================
      setup("clangd")
      setup("phpactor")
      setup("cssls")
      setup("cssmodules_ls")

      -- LUA
      setup("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
          },
        },
      })

      -- TYPESCRIPT
      setup("ts_ls", {
        on_attach = function(client, bufnr)
          client.server_capabilities.documentFormattingProvider = false
          on_attach(client, bufnr)
        end,
      })

      -- PYTHON
      setup("pyright", {
        on_new_config = function(new_config, root_dir)
          for _, venv in ipairs({ ".venv", "venv" }) do
            local python = root_dir .. "/" .. venv .. "/bin/python"
            if vim.fn.executable(python) == 1 then
              new_config.settings = { python = { pythonPath = python } }
              return
            end
          end
          new_config.settings = {
            python = { pythonPath = vim.fn.exepath("python3") or "python3" },
          }
        end,
      })

      -- TAILWIND
      setup("tailwindcss", {
        filetypes = {
          "html",
          "css",
          "javascript",
          "javascriptreact",
          "typescript",
          "typescriptreact",
          "vue",
          "svelte",
          "astro",
        },
        settings = {
          tailwindCSS = {
            includeLanguages = {
              ["astro-markdown"] = "html",
            },
          },
        },
      })
    end,
  },

  -- ======================
  -- CMP
  -- ======================
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/cmp-git",
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        mapping = cmp.mapping.preset.insert({
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<CR>"] = cmp.mapping.confirm(),

          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            else
              fallback()
            end
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),

        sources = cmp.config.sources({
          { name = "nvim_lsp" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })

      cmp.setup.filetype("gitcommit", {
        sources = {
          { name = "cmp_git" },
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })
    end,
  },
}
