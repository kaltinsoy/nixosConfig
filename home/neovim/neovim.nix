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
      # ── LSP servers ─────────────────────────────────────────────────
      nil                           # Nix LSP
      nixd                          # alternative Nix LSP (better features)
      pyright                       # Python
      ruff                          # Python linter + LSP (ruff-lsp merged into ruff)
      clang-tools                   # clangd (C/C++)
      lua-language-server           # Lua
      rust-analyzer                 # Rust
      typescript-language-server    # TypeScript/JS
      bash-language-server          # Bash
      yaml-language-server          # YAML
      taplo                         # TOML LSP
      marksman                      # Markdown LSP
      # HDL
      verilator                     # Verilog/SV lint (used by nvim-lint)

      # ── Formatters ──────────────────────────────────────────────────
      nixfmt-rfc-style              # Nix
      stylua                        # Lua
      black                         # Python
      isort                         # Python imports
      clang-tools                   # clang-format for C/C++
      rustfmt                       # Rust
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

  # ── NvChad config — managed via xdg.configFile ───────────────────────
  # NvChad's starter is pinned in flake inputs (nvchad-starter).
  # We copy the starter into ~/.config/nvim and overlay our custom/ layer.
  # On first launch, NvChad/lazy.nvim will pull plugins (needs internet).
  xdg.configFile = {
    # Base NvChad starter (read-only symlink from nix store)
    # We use a writable copy approach: link each subdirectory except custom/
    # so the user can add lazy-lock.json etc without permission issues.
    "nvim/init.lua".source = "${nvchad-starter}/init.lua";

    # Our custom layer overrides
    "nvim/lua/custom/chadrc.lua".text = ''
      -- NvChad custom config
      ---@type ChadrcConfig
      local M = {}

      M.ui = {
        theme            = "catppuccin",
        theme_toggle     = { "catppuccin", "one_light" },
        transparency     = false,
        statusline       = { theme = "default" },
        tabufline        = { enabled = true },
        cmp              = { style = "flat_dark" },
        telescope        = { style = "bordered" },
        lsp_semantic_tokens = true,
      }

      M.plugins = "custom.plugins"
      M.mappings = "custom.mappings"

      return M
    '';

    "nvim/lua/custom/plugins/init.lua".text = ''
      return {
        -- ── Theme ────────────────────────────────────────────────────
        {
          "catppuccin/nvim",
          name     = "catppuccin",
          priority = 1000,
          opts = { flavour = "mocha" },
        },

        -- ── LSP ──────────────────────────────────────────────────────
        {
          "neovim/nvim-lspconfig",
          config = function()
            require "custom.configs.lspconfig"
          end,
        },

        -- ── Formatting ───────────────────────────────────────────────
        {
          "stevearc/conform.nvim",
          event = "BufWritePre",
          config = function()
            require "custom.configs.conform"
          end,
        },

        -- ── Linting ──────────────────────────────────────────────────
        {
          "mfussenegger/nvim-lint",
          event = { "BufReadPost", "BufWritePost" },
          config = function()
            require "custom.configs.lint"
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
        },

        -- ── HDL / FPGA ───────────────────────────────────────────────
        {
          "suoto/hdl_checker",    -- HDL (VHDL/Verilog) language server integration
          ft  = { "vhdl", "verilog", "systemverilog" },
        },

        -- ── Nix ──────────────────────────────────────────────────────
        {
          "LnL7/vim-nix",
          ft = "nix",
        },
      }
    '';

    "nvim/lua/custom/configs/lspconfig.lua".text = ''
      local on_attach = require("plugins.configs.lspconfig").on_attach
      local capabilities = require("plugins.configs.lspconfig").capabilities

      local lspconfig = require "lspconfig"

      local servers = {
        -- Nix
        nixd        = {},
        -- Python
        pyright     = {},
        ruff_lsp    = {},
        -- C/C++
        clangd      = {
          cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
        },
        -- Lua
        lua_ls      = {
          settings = { Lua = { diagnostics = { globals = { "vim" } } } },
        },
        -- Rust
        rust_analyzer = {},
        -- TypeScript
        ts_ls       = {},
        -- Bash
        bashls      = {},
        -- YAML
        yamlls      = {},
        -- TOML
        taplo       = {},
        -- Markdown
        marksman    = {},
      }

      for name, opts in pairs(servers) do
        opts.on_attach    = on_attach
        opts.capabilities = capabilities
        lspconfig[name].setup(opts)
      end
    '';

    "nvim/lua/custom/configs/conform.lua".text = ''
      require("conform").setup {
        formatters_by_ft = {
          nix        = { "nixfmt" },
          lua        = { "stylua" },
          python     = { "isort", "black" },
          c          = { "clang_format" },
          cpp        = { "clang_format" },
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

    "nvim/lua/custom/configs/lint.lua".text = ''
      local lint = require "lint"

      lint.linters_by_ft = {
        python     = { "ruff" },
        verilog    = { "verilator" },
        systemverilog = { "verilator" },
        sh         = { "shellcheck" },
        nix        = { "nix" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost" }, {
        callback = function()
          lint.try_lint()
        end,
      })
    '';

    "nvim/lua/custom/mappings.lua".text = ''
      ---@type MappingsTable
      local M = {}

      M.general = {
        n = {
          -- LazyGit
          ["<leader>gg"] = { "<cmd>LazyGit<CR>",           "Open LazyGit" },
          -- DiffView
          ["<leader>gd"] = { "<cmd>DiffviewOpen<CR>",       "Open Diffview" },
          ["<leader>gD"] = { "<cmd>DiffviewClose<CR>",      "Close Diffview" },
          -- Trouble
          ["<leader>xx"] = { "<cmd>Trouble diagnostics toggle<CR>", "Diagnostics" },
          -- File manager (yazi)
          ["<leader>e"]  = { "<cmd>!yazi<CR>",              "Open Yazi" },
        },
      }

      return M
    '';
  };
}
