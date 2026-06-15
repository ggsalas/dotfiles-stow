return {
  -- jupytext: convierte .ipynb (JSON) a markdown al abrir, y de vuelta al guardar
  -- requiere el CLI `jupytext` (no disponible en Mason)
  {
    "GCBallesteros/jupytext.nvim",
    build = "mise exec python -- pip install jupytext",
    config = function()
      require("jupytext").setup({
        style = "hydrogen",
        output_extension = "auto", -- Default extension.
        force_ft = nil, -- Default filetype.
        custom_language_formatting = {},
      })

      -- Borrar archivos .py generados por jupytext al cerrar el buffer
      vim.api.nvim_create_autocmd({ "BufDelete", "VimLeavePre" }, {
        pattern = "*.ipynb",
        callback = function(e)
          local py_file = e.file:gsub("%.ipynb$", ".py")
          if vim.fn.filereadable(py_file) == 1 then
            vim.fn.delete(py_file)
          end
        end,
      })
    end,
  },

  -- molten-nvim: ejecucion de codigo y visualizacion de outputs
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = {
      "uv tool install pynvim --with nbformat --with jupyter_client --with ipykernel --with cairosvg --with pnglatex --with plotly --with pyperclip --force",
      ":UpdateRemotePlugins",
    },
    init = function()
      vim.g.molten_output_win_max_height = 12
      vim.g.molten_auto_open_output = false
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
    end,
    config = function()
      -- keymaps
      vim.keymap.set("n", "M", ":noautocmd MoltenEnterOutput<CR>", { desc = "open output window", silent = true })
      vim.keymap.set("n", "<leader>mh", ":MoltenHideOutput<CR>", { desc = "close output window", silent = true })

      vim.keymap.set("n", "<leader>mm", ":MoltenReevaluateCell<CR>", { desc = "run cell", silent = true })
      vim.keymap.set(
        "v",
        "<leader>mm",
        ":<C-u>MoltenEvaluateVisual<CR>gv",
        { desc = "run visual range", silent = true }
      )
      vim.keymap.set("n", "<leader>mA", ":MoltenReevaluateAll<CR>", { desc = "run all cells", silent = true })
      vim.keymap.set("n", "<leader>ml", ":MoltenEvaluateLine<CR>", { desc = "run line", silent = true })
      vim.keymap.set("n", "<leader>md", ":MoltenDelete<CR>", { desc = "delete Molten cell", silent = true })
      vim.keymap.set("n", "<leader>mD", ":%MoltenDelete<CR>", { desc = "delete all Molten outputs", silent = true })

      -- Sobrescribir ]] y [[ para navegación de celdas en archivos jupyter
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python", -- jupytext convierte .ipynb a python con style=hydrogen
        callback = function()
          vim.keymap.set("n", "]]", function()
            vim.cmd("MoltenHideOutput")
            vim.cmd("MoltenNext")
            vim.cmd("normal! zv") -- open fold if exists
            vim.cmd("normal! zt") -- scroll to put cursor at top
          end, { buffer = true, desc = "next cell", silent = true })

          vim.keymap.set("n", "[[", function()
            vim.cmd("MoltenHideOutput")
            vim.cmd("MoltenPrev")
            vim.cmd("normal! zv") -- open fold if exists
            vim.cmd("normal! zt") -- scroll to put cursor at top
          end, { buffer = true, desc = "prev cell", silent = true })

          vim.keymap.set("n", "<leader>]", function()
            vim.cmd("MoltenHideOutput")
            vim.cmd("MoltenNext")
            vim.cmd("normal! zv") -- open fold if exists
            vim.cmd("normal! zt") -- scroll to put cursor at top
            vim.cmd("MoltenReevaluateCell")
          end, { buffer = true, desc = "next cell", silent = true })
        end,
      })

      -- auto-init kernel e importar outputs al abrir un .ipynb
      local imb = function(e)
        vim.schedule(function()
          -- Buscar .venv recursivamente en directorios padres
          local find_venv = function(start_path)
            local path = start_path
            while path ~= "/" and path ~= "" do
              local venv = path .. "/.venv"
              if vim.fn.isdirectory(venv) == 1 then
                return venv
              end
              path = vim.fn.fnamemodify(path, ":h")
            end
            return nil
          end

          local file_dir = vim.fn.fnamemodify(e.file, ":p:h")
          local venv = find_venv(file_dir)
          if venv then
            vim.env.VIRTUAL_ENV = venv
            vim.env.PATH = venv .. "/bin:" .. vim.env.PATH
            vim.env.JUPYTER_PATH = venv .. "/share/jupyter"

            -- Si el kernel usa "python" relativo, reinstalarlo con ruta absoluta
            local kernel_json_path = venv .. "/share/jupyter/kernels/python3/kernel.json"
            local f = io.open(kernel_json_path, "r")
            if f then
              local content = f:read("a")
              f:close()
              local kernel_spec = vim.json.decode(content)
              if kernel_spec.argv[1] == "python" then
                vim.fn.system(venv .. "/bin/python -m ipykernel install --prefix " .. venv .. " --name python3")
              end
            end
          else
            vim.env.JUPYTER_PATH = vim.fn
              .system("mise exec python -- python -c 'import jupyter_core.paths as p; print(p.jupyter_path()[0])'")
              :gsub("\n", "")
          end

          local kernels = vim.fn.MoltenAvailableKernels()
          local try_kernel_name = function()
            local metadata = vim.json.decode(io.open(e.file, "r"):read("a"))["metadata"]
            return metadata.kernelspec.name
          end
          local ok, kernel_name = pcall(try_kernel_name)
          if not ok or not vim.tbl_contains(kernels, kernel_name) then
            kernel_name = nil
            local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
            if venv ~= nil then
              kernel_name = string.match(venv, "/.+/(.+)")
            end
          end
          if kernel_name ~= nil and vim.tbl_contains(kernels, kernel_name) then
            vim.cmd(("MoltenInit %s"):format(kernel_name))
          end
          vim.cmd("MoltenImportOutput")
        end)
      end

      vim.api.nvim_create_autocmd("BufAdd", {
        pattern = { "*.ipynb" },
        callback = imb,
      })
      vim.api.nvim_create_autocmd("BufAdd", {
        pattern = "*.ipynb",
        callback = function()
          vim.schedule(function()
            vim.opt.foldmethod = "expr"
            vim.opt.foldexpr = "getline(v:lnum)=~'^# %%' ? '>1' : getline(v:lnum-1)=~'^# %%' ? 1 : '='"
            vim.opt.foldlevel = 0
          end)
        end,
      })
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = { "*.ipynb" },
        callback = function(e)
          if vim.api.nvim_get_vvar("vim_did_enter") ~= 1 then
            imb(e)
          end
        end,
      })
    end,
  },
}
