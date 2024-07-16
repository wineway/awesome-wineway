(vim.cmd "setlocal tabstop=8 shiftwidth=8 expandtab!")
(var clangd-flags [:--background-index
                   :--fallback-style=LLVM
                   :--all-scopes-completion
                   :--clang-tidy
                   :--log=error
                   :--completion-style=detailed
                   :--pch-storage=memory
                   :--header-insertion=never
                   :--enable-config
                   :--offset-encoding=utf-16])
(local provider :clangd)
(fn custom-on-attach [client bufnr]
  ((. (require :lvim.lsp) :common_on_attach) client bufnr)
  (local opts {:buffer bufnr :noremap true :silent true})
  (vim.keymap.set :n :<leader>lh :<cmd>ClangdSwitchSourceHeader<cr> opts)
  (vim.keymap.set :x :<leader>lA :<cmd>ClangdAST<cr> opts)
  (vim.keymap.set :n :<leader>lH :<cmd>ClangdTypeHierarchy<cr> opts)
  (vim.keymap.set :n :<leader>lt :<cmd>ClangdSymbolInfo<cr> opts)
  (vim.keymap.set :n :<leader>lm :<cmd>ClangdMemoryUsage<cr> opts)
  (vim.keymap.set :n :<leader>le "<cmd>lua vim.lsp.buf.hover()<cr>" opts)
  ((. (require :clangd_extensions.inlay_hints) :setup_autocmd))
  ((. (require :clangd_extensions.inlay_hints) :set_inlay_hints)))
(local (status-ok project-config) (pcall require :rhel.clangd_wrl))
(when status-ok
  (set clangd-flags (vim.tbl_deep_extend :keep project-config clangd-flags)))
(fn custom-on-init [client bufnr]
  ((. (require :lvim.lsp) :common_on_init) client bufnr)
  ((. (require :clangd_extensions.config) :setup) {})
  (vim.cmd
  ;; "command ClangdToggleInlayHints lua require('clangd_extensions.inlay_hints').toggle_inlay_hints()
  "command -range ClangdAST lua require('clangd_extensions.ast').display_ast(<line1>, <line2>)
  command ClangdTypeHierarchy lua require('clangd_extensions.type_hierarchy').show_hierarchy()
  command ClangdSymbolInfo lua require('clangd_extensions.symbol_info').show_symbol_info()
  command -nargs=? -complete=customlist,s:memuse_compl ClangdMemoryUsage lua require('clangd_extensions.memory_usage').show_memory_usage('<args>' == 'expand_preamble')
  "))
(local opts {:cmd [provider (unpack clangd-flags)]
             :on_attach custom-on-attach
             :on_init custom-on-init})
((. (require :lvim.lsp.manager) :setup) :clangd opts)
(set lvim.builtin.dap.on_config_done
     (fn [dap]
       (set dap.adapters.codelldb
            {:executable {:args [:--port "${port}"] :command :codelldb}
             :port "${port}"
             :type :server})
       (set dap.configurations.cpp
            [{:cwd "${workspaceFolder}"
              :name "Launch file"
              :program (fn []
                         (var path nil)
                         (vim.ui.input {:default (vim.loop.cwd)
                                        :prompt "Path to executable: "
                                        :completion :file}
                                       (fn [input] (set path input)))
                         (vim.cmd :redraw)
                         path)
              :request :launch
              :stopOnEntry false
              :type :codelldb}])
       (set dap.configurations.c dap.configurations.cpp)))
