-- Neo-tree is a Neovim plugin to browse the file system
-- https://github.com/nvim-neo-tree/neo-tree.nvim

return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },
  cmd = 'Neotree',
  keys = {
    { '\\', ':Neotree reveal<CR>', { desc = 'NeoTree reveal' } },
    {
      '<leader>be',
      function()
        require('neo-tree.command').execute { source = 'buffers', toggle = true }
      end,
      desc = 'Buffer explorer',
    },
    -- {
    --   '<c-b>',
    --   function()
    --     local actions = require 'telescope.actions'
    --     return actions.delete_buffer + actions.move_to_top
    --   end,
    --   desc = 'Delete buffer',
    -- },
  },
  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },
  },
}
