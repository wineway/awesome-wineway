(local registry (require :mason-registry))
(local pkg-name :haskell-language-server)
(set vim.g.haskell_tools {:dap {}
                          :hls {:on_attach (fn [client bufnr ht]
                                             ((. (require :lvim.lsp)
                                                 :common_on_attach) client
                                                                                                                                         bufnr))}
                          :tools {}})
(when (not (registry.is_installed pkg-name))
  (vim.notify_once (string.format "Installing [%s]" pkg-name)
                   vim.log.levels.INFO)
  (local pkg (registry.get_package pkg-name))
  (: (pkg:install) :once :closed
     (fn []
       (when (pkg:is_installed)
         (vim.schedule (fn []
                         (vim.notify_once (string.format "Installation complete for [%s]"
                                                         pkg-name)
                                          vim.log.levels.INFO)))))))
