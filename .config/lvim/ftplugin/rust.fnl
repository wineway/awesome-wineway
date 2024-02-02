(set vim.g.rustaceanvim {:dap {}
                         :server {:on_attach (fn [client bufnr]
                                               ((. (require :lvim.lsp)
                                                   :common_on_attach) client
                                                                                                                                             bufnr))
                                  :settings {:rust-analyzer {}}}
                         :tools {}})
