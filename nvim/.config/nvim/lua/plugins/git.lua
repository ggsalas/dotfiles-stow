return {
  -- Git for vim
  --------------
  {
    "tpope/vim-fugitive",
  },

  -- Enables GBrowse and completions for commit messages
  ------------------------------------------------------
  {
    "tpope/vim-rhubarb",
  },

  -- GDiffBranch: compare current branch against another branch using quickfix + fugitive
  -- Usage: :GDiffBranch [branch]  (defaults to main or master)
  -- Keymap: <leader>gd
  -- In quickfix: dd = open diff, <CR> = open file
  {
    "tpope/vim-fugitive",
    config = function()
      local function detect_base_branch()
        local result = vim.fn.system("git branch --list main master")
        if result:match("main") then
          return "main"
        end
        return "master"
      end

      -- to return filename only
      function DiffBranchQfText(info)
        local items = vim.fn.getqflist({ id = info.id, items = 1 }).items
        local lines = {}
        for i = info.start_idx, info.end_idx do
          table.insert(lines, vim.fn.bufname(items[i].bufnr))
        end
        return lines
      end

      -- to only have diff (or file) and qfix windows
      local function prepare_main_window()
        local wins = vim.api.nvim_list_wins()
        local other_wins = {} -- no quickfix windows

        for _, win in ipairs(wins) do
          local buf = vim.api.nvim_win_get_buf(win)
          if vim.bo[buf].buftype ~= "quickfix" then
            table.insert(other_wins, win)
          end
        end

        local main_win = other_wins[1]
        if not main_win then
          vim.cmd("above new")
          main_win = vim.api.nvim_get_current_win()
        else
          for i = 2, #other_wins do
            pcall(vim.api.nvim_win_close, other_wins[i], true)
          end
        end

        vim.api.nvim_set_current_win(main_win)
        vim.cmd("diffoff")
      end

      -- to get filename under cursor
      local function get_qf_filename()
        local lnum = vim.fn.line(".")
        local qflist = vim.fn.getqflist()
        local entry = qflist[lnum]
        if not entry then
          return nil
        end
        local filename = vim.fn.bufname(entry.bufnr)
        if filename == "" then
          return nil
        end
        return filename
      end

      vim.api.nvim_create_user_command("GDiffBranch", function(opts)
        local branch = opts.args ~= "" and opts.args or detect_base_branch()
        local output = vim.fn.systemlist("git diff --name-only " .. vim.fn.shellescape(branch))

        if vim.v.shell_error ~= 0 then
          vim.notify("Error running git diff against " .. branch, vim.log.levels.ERROR)
          return
        end

        if #output == 0 or (output[1] and output[1] == "") then
          vim.notify("No changes compared to " .. branch, vim.log.levels.INFO)
          return
        end

        local items = {}
        for _, file in ipairs(output) do
          if file ~= "" then
            table.insert(items, { filename = file })
          end
        end

        vim.fn.setqflist({}, " ", {
          title = "DiffBranch: " .. branch,
          items = items,
          quickfixtextfunc = "v:lua.DiffBranchQfText",
        })
        vim.cmd("copen")
        vim.b.diff_branch = branch
      end, { nargs = "?", desc = "Show files changed compared to a branch" })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function()
          vim.schedule(function()
            local branch = vim.b.diff_branch
            if not branch then
              return
            end

            vim.keymap.set("n", "dd", function()
              local filename = get_qf_filename()
              if not filename then
                return
              end

              prepare_main_window()
              vim.cmd("edit " .. vim.fn.fnameescape(filename))
              vim.cmd("Gvdiffsplit " .. branch .. ":%")
              vim.cmd("wincmd l")
            end, { buffer = true, desc = "Diff against " .. branch })

            vim.keymap.set("n", "<CR>", function()
              local filename = get_qf_filename()
              if not filename then
                return
              end

              prepare_main_window()
              vim.cmd("edit " .. vim.fn.fnameescape(filename))
            end, { buffer = true, desc = "Open file" })
          end)
        end,
      })

      vim.keymap.set("n", "<leader>gd", ":GDiffBranch<CR>", { silent = true, desc = "Diff against base branch" })
    end,
  },

  -- git decorations
  ------------------
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gs = package.loaded.gitsigns

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              return "]c"
            end
            vim.schedule(function()
              gs.next_hunk()
            end)
            return "<Ignore>"
          end, { expr = true })

          map("n", "[c", function()
            if vim.wo.diff then
              return "[c"
            end
            vim.schedule(function()
              gs.prev_hunk()
            end)
            return "<Ignore>"
          end, { expr = true })

          -- Actions
          map("n", "<leader>ca", gs.stage_hunk)
          map("n", "<leader>cd", gs.reset_hunk)
          map("v", "<leader>ca", function()
            gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end)
          map("v", "<leader>cd", function()
            gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end)
          map("n", "<leader>cu", gs.undo_stage_hunk)
          map("n", "<leader>cp", gs.preview_hunk)
          map("n", "<leader>cb", function()
            gs.blame_line({ full = true })
          end)
          -- map('n', '<leader>tb', gs.toggle_current_line_blame)

          -- Text object
          map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
        end,
      })
    end,
  },
}
