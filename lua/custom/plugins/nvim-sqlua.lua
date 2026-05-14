return {
  'xemptuous/sqlua.nvim',
  lazy = true,
  cmd = 'SQLua',
  config = function()
    require('sqlua').setup {
      -- the parent folder that databases will be placed, holding
      -- various tmp files and other saved queries.
      db_save_location = '~/.local/share/nvim/sqlua/',
      -- where to save the json config containing connection information
      connections_save_location = '~/.local/share/nvim/sqlua/connections.json',
      -- the default limit attached to queries
      -- currently only works on "Data" command under a table
      default_limit = 200,
      -- whether to introspect the database on SQLua open or when first expanded
      -- through the sidebar
      load_connections_on_start = false,
      keybinds = {
        execute_query = '<leader>r',
        activate_db = '<C-a>',
      },
    }
  end,
}
