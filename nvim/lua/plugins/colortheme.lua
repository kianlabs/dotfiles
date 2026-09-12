local palette = vim.fn.expand("~/.cache/matugen/nvim-base16.lua")

local function has_palette()
  return (vim.uv or vim.loop).fs_stat(palette) ~= nil
end

return {
  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    cond = has_palette,

    config = function()
      local function apply()
        local ok, colors = pcall(dofile, palette)

        if not ok or type(colors) ~= "table" then
          return
        end

        -- Apply Matugen / Base16
        require("base16-colorscheme").setup(colors)

        local hl = vim.api.nvim_set_hl

        ----------------------------------------------------------------------
        -- TREESITTER - RICH SYNTAX COLORS
        ----------------------------------------------------------------------

        -- Keywords
        hl(0, "@keyword", {
          fg = "#C792EA",
          bold = true,
        })

        hl(0, "@keyword.function", {
          fg = "#C792EA",
          bold = true,
        })

        hl(0, "@keyword.return", {
          fg = "#C792EA",
          bold = true,
        })

        hl(0, "@keyword.conditional", {
          fg = "#C792EA",
          bold = true,
        })

        hl(0, "@keyword.repeat", {
          fg = "#C792EA",
          bold = true,
        })

        hl(0, "@keyword.import", {
          fg = "#C792EA",
          bold = true,
        })

        -- Variables
        hl(0, "@variable", {
          fg = "#D8DEE9",
        })

        hl(0, "@variable.builtin", {
          fg = "#F07178",
        })

        hl(0, "@variable.parameter", {
          fg = "#F78C6C",
        })

        hl(0, "@variable.member", {
          fg = "#FFCB6B",
        })

        -- Functions
        hl(0, "@function", {
          fg = "#82AAFF",
          bold = true,
        })

        hl(0, "@function.call", {
          fg = "#82AAFF",
        })

        hl(0, "@function.builtin", {
          fg = "#F07178",
        })

        -- Methods
        hl(0, "@function.method", {
          fg = "#89DDFF",
        })

        hl(0, "@function.method.call", {
          fg = "#89DDFF",
        })

        -- Strings
        hl(0, "@string", {
          fg = "#C3E88D",
        })

        hl(0, "@string.escape", {
          fg = "#89DDFF",
        })

        hl(0, "@string.special", {
          fg = "#FFCB6B",
        })

        -- Numbers
        hl(0, "@number", {
          fg = "#F78C6C",
        })

        hl(0, "@number.float", {
          fg = "#F78C6C",
        })

        -- Boolean
        hl(0, "@boolean", {
          fg = "#F78C6C",
          bold = true,
        })

        -- Constants
        hl(0, "@constant", {
          fg = "#FFCB6B",
        })

        hl(0, "@constant.builtin", {
          fg = "#FF5370",
        })

        -- Types
        hl(0, "@type", {
          fg = "#FFCB6B",
        })

        hl(0, "@type.builtin", {
          fg = "#FFCB6B",
          bold = true,
        })

        -- Properties
        hl(0, "@property", {
          fg = "#FFCB6B",
        })

        hl(0, "@field", {
          fg = "#FFCB6B",
        })

        -- Operators
        hl(0, "@operator", {
          fg = "#89DDFF",
        })

        -- Punctuation
        hl(0, "@punctuation.delimiter", {
          fg = "#BFC7D5",
        })

        hl(0, "@punctuation.bracket", {
          fg = "#BFC7D5",
        })

        hl(0, "@punctuation.special", {
          fg = "#89DDFF",
        })

        -- Comments
        hl(0, "@comment", {
          fg = "#697098",
          italic = true,
        })

        -- HTML / JSX / TSX
        hl(0, "@tag", {
          fg = "#F07178",
        })

        hl(0, "@tag.attribute", {
          fg = "#FFCB6B",
        })

        hl(0, "@tag.delimiter", {
          fg = "#89DDFF",
        })

        ----------------------------------------------------------------------
        -- LSP SEMANTIC TOKENS
        -- Ini penting karena LSP bisa menimpa warna Treesitter.
        ----------------------------------------------------------------------

        hl(0, "@lsp.type.variable", {
          fg = "#D8DEE9",
        })

        hl(0, "@lsp.type.parameter", {
          fg = "#F78C6C",
        })

        hl(0, "@lsp.type.property", {
          fg = "#FFCB6B",
        })

        hl(0, "@lsp.type.function", {
          fg = "#82AAFF",
          bold = true,
        })

        hl(0, "@lsp.type.method", {
          fg = "#89DDFF",
        })

        hl(0, "@lsp.type.class", {
          fg = "#FFCB6B",
          bold = true,
        })

        hl(0, "@lsp.type.interface", {
          fg = "#FFCB6B",
        })

        hl(0, "@lsp.type.type", {
          fg = "#FFCB6B",
        })

        hl(0, "@lsp.type.typeParameter", {
          fg = "#F78C6C",
        })

        hl(0, "@lsp.type.enum", {
          fg = "#FFCB6B",
        })

        hl(0, "@lsp.type.enumMember", {
          fg = "#F78C6C",
        })

        hl(0, "@lsp.type.namespace", {
          fg = "#C792EA",
        })

        hl(0, "@lsp.type.decorator", {
          fg = "#C792EA",
        })

        hl(0, "@lsp.type.macro", {
          fg = "#C792EA",
        })

        -- Built-in / default library
        hl(0, "@lsp.mod.defaultLibrary", {
          fg = "#F07178",
        })

        ----------------------------------------------------------------------
        -- LUALINE
        ----------------------------------------------------------------------

        pcall(function()
          require("lualine").setup({
            options = {
              theme = "auto",
            },
          })
        end)
      end

      -- Apply saat startup
      apply()

      -- Bisa dipanggil manual dengan:
      -- :lua MatugenReload()
      _G.MatugenReload = apply
    end,
  },

  --------------------------------------------------------------------------
  -- FALLBACK THEME
  -- Dipakai hanya kalau palette Matugen tidak tersedia.
  --------------------------------------------------------------------------

  {
    "catppuccin/nvim",
    lazy = false,
    name = "catppuccin",
    priority = 1000,

    cond = function()
      return not has_palette()
    end,

    config = function()
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
}
