return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      adapters = {
        -- 7B untuk chat
        qwen7b = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "qwen7b",
            env = { url = "http://127.0.0.1:1234" },
            schema = {
              model = { default = "qwen2.5-coder-7b" },
              temperature = { default = 0.2 },
              max_tokens = { default = 2048 },
            },
          })
        end,
        -- 1.5B untuk inline/autocomplete
        qwen1b = function()
          return require("codecompanion.adapters").extend("openai_compatible", {
            name = "qwen1b",
            env = { url = "http://127.0.0.1:1235" },
            schema = {
              model = { default = "qwen2.5-coder-1.5b" },
              temperature = { default = 0.1 },
              max_tokens = { default = 512 },
            },
          })
        end,
      },
      strategies = {
        -- Chat pakai 7B
        chat = {
          adapter = "qwen7b",
          keymaps = {
            send = { modes = { n = "<CR>", i = "<C-s>" } },
            close = { modes = { n = "q" } },
          },
        },
        -- Inline edit pakai 7B
        inline = {
          adapter = "qwen7b",
        },
        -- Autocomplete pakai 1.5B
        agent = {
          adapter = "qwen1b",
        },
      },
      display = {
        chat = {
          window = {
            layout = "vertical",
            width = 0.35,
          },
        },
      },
    })
  end,
  keys = {
    { "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", desc = "CodeCompanion: Toggle Chat" },
    { "<leader>ca", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion: Actions" },
    { "<leader>ci", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "CodeCompanion: Inline" },
    { "<leader>cd", "<cmd>CodeCompanionChat Add<cr>", mode = { "v" }, desc = "CodeCompanion: Add to Chat" },
  },
}
