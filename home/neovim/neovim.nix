{ pkgs, nvchad-starter, ... }:

{
  # ── Neovim binary ─────────────────────────────────────────────────────
  programs.neovim = {
    enable        = true;
    defaultEditor = true;
    viAlias       = true;
    vimAlias      = true;
    withNodeJs    = true;
    withPython3   = true;
    withRuby      = false;

    # Python providers (for plugins that need pynvim)
    extraPython3Packages = p: with p; [ pynvim ];

    # Extra packages available in Neovim's PATH
    extraPackages = with pkgs; [
      # ── LSP servers (Disabled) ──────────────────────────────────────
      # nixd, pyright, ruff, clang-tools, lua-ls, rust-analyzer, etc. disabled

      # HDL
      verilator                     # Verilog/SV lint (used by nvim-lint)

      # ── Formatters & Linters ────────────────────────────────────────
      nixfmt                        # Nix
      stylua                        # Lua
      black                         # Python
      isort                         # Python imports
      rustfmt                       # Rust
      clang-tools                   # C/C++ (clang-format)
      shfmt                         # Shell script formatting
      shellcheck                    # Shell script linting
      prettier                      # JS/TS/HTML/CSS/JSON/YAML/Markdown

      # ── Runtime deps ────────────────────────────────────────────────
      ripgrep                       # Telescope live grep
      fd                            # Telescope file finder
      gcc                           # Treesitter parser compilation
      gnumake
      nodejs_22                     # Some plugins require Node
      tree-sitter                   # CLI (optional)
      lazygit                       # LazyGit terminal UI
      git
    ];
  };

  # ── NvChad v2.5 config — managed via xdg.configFile ───────────────────
  # NvChad's starter is pinned in flake inputs (nvchad-starter).
  # We link the starter files (init.lua, options, autocmds, lazy config)
  # and provide user custom configurations (chadrc, plugins, lsp, formatting).
  xdg.configFile = {
    # Base NvChad starter files
    "nvim/init.lua".source          = "${nvchad-starter}/init.lua";
    "nvim/lua/options.lua".source   = "${nvchad-starter}/lua/options.lua";
    "nvim/lua/autocmds.lua".source  = "${nvchad-starter}/lua/autocmds.lua";
    "nvim/lua/configs/lazy.lua".source = "${nvchad-starter}/lua/configs/lazy.lua";

    # NvChad theme & UI overrides
    "nvim/lua/chadrc.lua".text = ''
      ---@type ChadrcConfig
      local M = {}

      M.base46 = {
        theme = "catppuccin",
        transparency = false,
        hl_override = {
          Comment = { italic = true },
          ["@comment"] = { italic = true },
        },
      }

      M.ui = {
        tabufline = {
          enabled = true,
          lazyload = false,
        },
        statusline = {
          theme = "default",
        },
        telescope = {
          style = "bordered",
        },
        cmp = {
          style = "flat_dark",
        },
      }

      M.nvdash = {
        load_on_startup = true,
      }

      return M
    '';

    # Additional plugins
    "nvim/lua/plugins/init.lua".text = ''
      return {
        -- ── Formatting ───────────────────────────────────────────────
        {
          "stevearc/conform.nvim",
          event = "BufWritePre",
          opts  = require "configs.conform",
        },

        -- ── LSP (Disabled) ───────────────────────────────────────────
        {
          "neovim/nvim-lspconfig",
          enabled = false,
        },

        -- ── Linting ──────────────────────────────────────────────────
        {
          "mfussenegger/nvim-lint",
          event = { "BufReadPost", "BufWritePost" },
          config = function()
            require "configs.lint"
          end,
        },

        -- ── Git ──────────────────────────────────────────────────────
        {
          "kdheepak/lazygit.nvim",
          lazy = true,
          cmd  = { "LazyGit", "LazyGitCurrentFile" },
          dependencies = { "nvim-lua/plenary.nvim" },
        },
        {
          "sindrets/diffview.nvim",
          lazy = true,
          cmd  = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
        },

        -- ── Editing ───────────────────────────────────────────────────
        {
          "kylechui/nvim-surround",
          version = "*",
          event   = "VeryLazy",
          config  = function() require("nvim-surround").setup({}) end,
        },
        {
          "folke/todo-comments.nvim",
          event  = "BufReadPost",
          config = function() require("todo-comments").setup() end,
        },
        {
          "folke/trouble.nvim",
          lazy = true,
          cmd  = "Trouble",
          opts = {},
        },

        -- ── HDL / FPGA ───────────────────────────────────────────────
        {
          "suoto/hdl_checker",
          ft = { "vhdl", "verilog", "systemverilog" },
        },

        -- ── Nix ──────────────────────────────────────────────────────
        {
          "LnL7/vim-nix",
          ft = "nix",
        },
      }
    '';

    # LSP configuration (Disabled)
    "nvim/lua/configs/lspconfig.lua".text = ''
      -- All language servers disabled
    '';

    # Formatting
    "nvim/lua/configs/conform.lua".text = ''
      return {
        formatters_by_ft = {
          nix        = { "nixfmt" },
          lua        = { "stylua" },
          python     = { "isort", "black" },
          c          = { "clang-format" },
          cpp        = { "clang-format" },
          rust       = { "rustfmt" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          json       = { "prettier" },
          yaml       = { "prettier" },
          markdown   = { "prettier" },
          sh         = { "shfmt" },
        },
        format_on_save = {
          lsp_fallback = true,
          timeout_ms   = 2000,
        },
      }
    '';

    # Linting
    "nvim/lua/configs/lint.lua".text = ''
      local lint = require "lint"

      lint.linters_by_ft = {
        python        = { "ruff" },
        verilog       = { "verilator" },
        systemverilog = { "verilator" },
        sh            = { "shellcheck" },
        nix           = { "nix" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    '';

    # Keymaps
    "nvim/lua/mappings.lua".text = ''
      require "nvchad.mappings"

      local map = vim.keymap.set

      map("n", ";", ":", { desc = "CMD enter command mode" })
      map("i", "jk", "<ESC>", { desc = "Escape" })

      -- LazyGit
      map("n", "<leader>gg", "<cmd>LazyGit<CR>", { desc = "Open LazyGit" })

      -- DiffView
      map("n", "<leader>gd", "<cmd>DiffviewOpen<CR>", { desc = "Open Diffview" })
      map("n", "<leader>gD", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" })

      -- Trouble
      map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", { desc = "Diagnostics (Trouble)" })

      -- File manager (Yazi)
      map("n", "<leader>e", "<cmd>!yazi<CR>", { desc = "Open Yazi" })
    '';
  };
}
