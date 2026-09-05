return {
  -- jupytext: convierte .ipynb (JSON) a markdown al abrir, y de vuelta al guardar
  -- requiere el CLI `jupytext` (no disponible en Mason)
  {
    "GCBallesteros/jupytext.nvim",
    build = "mise exec python -- pip install jupytext",
    config = function()
      require("jupytext").setup({
        format = "auto:hydrogen", -- Hydrogen cells (# %%) con extensión según el lenguaje
      })

      -- Borrar archivos .py generados por jupytext al cerrar el buffer
      local jupytext_group = vim.api.nvim_create_augroup("JupytextCleanup", { clear = true })
      
      -- Antes de guardar, cerrar cualquier buffer .py asociado que cause E139
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = jupytext_group,
        pattern = "*.ipynb",
        callback = function(e)
          -- jupytext genera el .py con la misma raíz que el .ipynb
          local py_file = vim.fn.resolve(vim.fn.expand(e.file:gsub("%.ipynb$", ".py")))
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
              local buf_name = vim.fn.resolve(vim.api.nvim_buf_get_name(buf))
              if buf_name == py_file then
                vim.api.nvim_buf_delete(buf, { force = true })
              end
            end
          end
        end,
      })
      
      vim.api.nvim_create_autocmd({ "BufDelete", "VimLeavePre" }, {
        group = jupytext_group,
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
      local molten_group = vim.api.nvim_create_augroup("MoltenConfig", { clear = true })

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
        group = molten_group,
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

      -- Guardar PATH original para no contaminarlo
      local original_path = vim.env.PATH

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

      -- auto-init kernel e importar outputs al abrir un .ipynb
      local imb = function(e)
        vim.schedule(function()
          local file_dir = vim.fn.fnamemodify(e.file, ":p:h")
          local venv = find_venv(file_dir)
          if venv then
            vim.env.VIRTUAL_ENV = venv
            -- Siempre partir del PATH original para no acumular entradas
            vim.env.PATH = venv .. "/bin:" .. original_path
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
            local f = io.open(e.file, "r")
            if not f then
              return nil
            end
            local content = f:read("a")
            f:close()
            local metadata = vim.json.decode(content)["metadata"]
            return metadata.kernelspec.name
          end
          local ok, kernel_name = pcall(try_kernel_name)
          if not ok or not vim.tbl_contains(kernels, kernel_name) then
            kernel_name = nil
            local venv_env = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX")
            if venv_env ~= nil then
              kernel_name = string.match(venv_env, "/.+/(.+)")
            end
          end
          if kernel_name ~= nil and vim.tbl_contains(kernels, kernel_name) then
            vim.cmd(("MoltenInit %s"):format(kernel_name))
          end
          vim.cmd("MoltenImportOutput")
        end)
      end

      -- Usar BufAdd para inicializar molten (se ejecuta una vez al crear el buffer,
      -- a diferencia de BufWinEnter que se ejecuta en cada cambio de ventana)
      vim.api.nvim_create_autocmd("BufAdd", {
        group = molten_group,
        pattern = "*.ipynb",
        callback = imb,
      })

      -- Configurar folding cuando el kernel esté listo
      vim.api.nvim_create_autocmd("User", {
        group = molten_group,
        pattern = "MoltenKernelReady",
        callback = function()
          -- Verificar que sea un buffer .ipynb
          if vim.fn.expand("%:e") == "ipynb" then
            vim.schedule(function()
              vim.opt_local.foldmethod = "expr"
              vim.opt_local.foldexpr = "getline(v:lnum)=~'^# %%' ? '>1' : getline(v:lnum-1)=~'^# %%' ? 1 : '='"
              vim.opt_local.foldlevel = 0
            end)
          end
        end,
      })
    end,
  },
}
