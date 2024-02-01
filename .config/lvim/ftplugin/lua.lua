local util = require 'lspconfig.util'

local root_files = {
  '.luarc.json',
  '.luarc.jsonc',
  '.luacheckrc',
  '.stylua.toml',
  'stylua.toml',
  'selene.toml',
  'selene.yml',
}

require("lvim.lsp.manager").setup("lua_ls", {
    cmd = { 'lua-language-server' },
    filetypes = { 'lua' },
    root_dir = function(fname)
      local root = util.root_pattern(unpack(root_files))(fname)
      if root and root ~= vim.env.HOME then
        return root
      end
      root = util.root_pattern 'lua/'(fname)
      if root then
        return root .. '/lua/'
      end
    end,
    single_file_support = true,
    log_level = vim.lsp.protocol.MessageType.Warning,
  })
