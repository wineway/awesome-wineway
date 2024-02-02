(vim.cmd "setlocal tabstop=8 shiftwidth=8 expandtab!")
(local util (require :lspconfig.util))
(local root-files [:.luarc.json
                   :.luarc.jsonc
                   :.luacheckrc
                   :.stylua.toml
                   :stylua.toml
                   :selene.toml
                   :selene.yml])
((. (require :lvim.lsp.manager) :setup) :lua_ls
                                        {:cmd [:lua-language-server]
                                         :filetypes [:lua]
                                         :log_level vim.lsp.protocol.MessageType.Warning
                                         :root_dir (fn [fname]
                                                     (var root
                                                          ((util.root_pattern (unpack root-files)) fname))
                                                     (when (and root
                                                                (not= root
                                                                      vim.env.HOME))
                                                       (lua "return root"))
                                                     (set root
                                                          ((util.root_pattern :lua/) fname))
                                                     (when root
                                                       (.. root :/lua/)))
                                         :single_file_support true})
