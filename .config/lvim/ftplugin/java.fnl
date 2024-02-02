(local registry (require :mason-registry))
(local pkg-name :jdtls)
(fn start-lsp []
  (fn resolve-lsp-bin-path [bin]
    (let [path (require :mason-core.path)] (path.bin_prefix bin)))

  (local path (require :jdtls.path))

  (fn find-root [markers bufname]
    (set-forcibly! bufname
                   (or bufname
                       (vim.api.nvim_buf_get_name (vim.api.nvim_get_current_buf))))
    (var dirname (vim.fn.fnamemodify bufname ":p:h"))

    (fn getparent [p] (vim.fn.fnamemodify p ":h"))

    (fn contains-marks [name]
      (each [_ marker (ipairs markers)]
        (when (vim.loop.fs_stat (path.join name marker)) (lua "return true"))))

    (while (not= (getparent dirname) dirname)
      (when (contains-marks dirname)
        (when (not (contains-marks (getparent dirname)))
          (lua "return dirname")))
      (set dirname (getparent dirname))))

  (local capabilities ((. (require :lvim.lsp) :common_capabilities)))
  (local extended-client-capabilities
         (. (require pkg-name) :extendedClientCapabilities))
  (set extended-client-capabilities.resolveAdditionalTextEditsSupport true)
  (local config {: capabilities
                 :cmd [(resolve-lsp-bin-path pkg-name)]
                 :init_options {:extendedClientCapabilities extended-client-capabilities}
                 :on_attach (fn [client bufnr]
                              ((. (require :lvim.lsp) :common_on_attach) client
                                                                         bufnr))
                 :root_dir (find-root [:pom.xml])
                 :settings {:java {:configuration {:references {:includeDecompiledSources true}
                                                   :updateBuildConfiguration :automatic}
                                   :eclipse {:downloadSources true}
                                   :implementationsCodeLens {:enabled true}
                                   :import {:maven {:enabled true}}
                                   :inlayHints {:parameterNames {:enabled :all}}
                                   :maven {:downloadSources true}
                                   :references {:includeDecompiledSources true}
                                   :referencesCodeLens {:enabled true}}}
                 :signatureHelp {:enabled true}})
  (vim.api.nvim_create_autocmd [:BufWritePost]
                               {:callback (fn []
                                            (local (_ _)
                                                   (pcall vim.lsp.codelens.refresh)))
                                :pattern [:*.java]})
  ((. (require :jdtls) :start_or_attach) config))
(if (not (registry.is_installed pkg-name))
    (let [pkg (registry.get_package pkg-name)]
      (: (pkg:install) :once :closed
         (fn []
           (when (pkg:is_installed)
             (vim.schedule (fn []
                             (vim.notify_once (string.format "Installation complete for [%s]"
                                                             pkg-name)
                                              vim.log.levels.INFO)
                             (start-lsp))))))) (start-lsp))	
