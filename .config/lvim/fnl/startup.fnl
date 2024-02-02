(set lvim.builtin.dap.active true)
(set lvim.colorscheme :NeoSolarized)
(set lvim.format_on_save false)
(vim.diagnostic.config {:virtual_text true})
(tset lvim.lsp.buffer_mappings.normal_mode :gl
      [vim.lsp.buf.outgoing_calls :outgoing_calls])
(tset lvim.lsp.buffer_mappings.normal_mode :gk
      [vim.lsp.buf.incoming_calls :incoming_calls])
(tset lvim.lsp.buffer_mappings.normal_mode :mh
      [vim.lsp.buf.document_highlight :hightlight])
(tset lvim.lsp.buffer_mappings.normal_mode :ml
      [vim.lsp.buf.clear_references "cancel hightlight"])
(tset lvim.builtin.which_key.mappings :m
      {:c [:<Cmd>LTCreateBookmark<CR> "create bookmark"]
       :d [:<Cmd>LTDeleteBookmark<CR> "delete bookmark"]
       :n [:<Cmd>LTCreateNotebook<CR> "create notebook"]
       :name :bookmark
       :o [:<Cmd>LTOpenNotebook<CR> "open nodebook"]})


;; gq - format code
;; zc - Close (fold) the current fold under the cursor.
;; zo - Open (unfold) the current fold under the cursor.
;; za - Toggle between closing and opening the fold under the cursor.
;; zR - Open all folds in the current buffer.
;; zM - Close all folds in the current buffer .
;; folding powered by treesitter
;; https://github.com/nvim-treesitter/nvim-treesitter#folding
;; look for foldenable: https://github.com/neovim/neovim/blob/master/src/nvim/options.lua
;; Vim cheatsheet, look for folds keys: https://devhints.io/vim
(set vim.opt.foldmethod :expr)
(set vim.opt.foldexpr "nvim_treesitter#foldexpr()")
(set vim.opt.foldtext
     "substitute(getline(v:foldstart),'\\\\t',repeat('\\ ',&tabstop),'g').'...'.trim(getline(v:foldend)) . ' (' . (v:foldend - v:foldstart + 1) . ' lines)'")
(set vim.opt.foldenable false)
(set vim.opt.foldlevel 1)
(set lvim.builtin.treesitter.highlight.enable true)

;; auto install treesitter parsers
(set lvim.builtin.treesitter.ensure_installed [:cpp :c :lua])

;; scala
;; function to display metals status in the statusline
(fn metals-status []
  (let [status (. vim.g :metals_status)] (if (= status nil) "" status)))
(local components (require :lvim.core.lualine.components))
(set lvim.builtin.lualine.sections.lualine_c
	;; NOTE: There is no way to append a component, so we need to include the components
	;; here that are already supplied by lunarvim in `lualine_c`
     [components.diff components.python_env metals-status])
(tset lvim.builtin.which_key.mappings :M
      {:d [:<Cmd>MetalsRunDoctor<CR> "Metals Doctor"]
       :i [:<Cmd>MetalsInfo<CR> "Metals Info"]
       :name :Metals
       :r [:<Cmd>MetalsRestartBuild<CR> "Restart Build Server"]
       :u [:<Cmd>MetalsUpdate<CR> "Update Metals"]})
(fn metals-configs []
  (let [lvim-lsp (require :lvim.lsp)
        metals-config ((. (require :metals) :bare_config))]
    (set metals-config.on_init lvim-lsp.common_on_init)
    (set metals-config.on_exit lvim-lsp.common_on_exit)
    (set metals-config.capabilities (lvim-lsp.common_capabilities))
    (set metals-config.on_attach
         (fn [client bufnr]
           (lvim-lsp.common_on_attach client bufnr)
           (vim.keymap.set :n :<leader>gd vim.lsp.buf.format)
           ((. (require :metals) :setup_dap))))
    (set metals-config.settings
         {:excludedPackages {}
          :showImplicitArguments true
          :showImplicitConversionsAndClasses true
          :showInferredType true
          :superMethodLensesEnabled true})
    (set metals-config.init_options.statusBarProvider false)
    (vim.api.nvim_create_autocmd :FileType
                                 {:callback (fn []
                                              ((. (require :metals)
                                                  :initialize_or_attach) metals-config))
                                  :group (vim.api.nvim_create_augroup :nvim-metals
                                                                      {:clear true})
                                  :pattern [:scala :sbt]})))
(table.insert lvim.plugins [:p00f/clangd_extensions.nvim
                            {1 :Tsuzat/NeoSolarized.nvim
                             :config (fn []
                                       (vim.cmd " colorscheme NeoSolarized "))
                             :lazy false
                             :priority 1000}
                            :ldelossa/litee.nvim
                            :ldelossa/litee-calltree.nvim
                            :ldelossa/litee-bookmarks.nvim
                            :kevinhwang91/nvim-bqf
                            :nvim-lua/plenary.nvim
                            {1 :scalameta/nvim-metals
                             :config (fn [] (metals-configs))
                             :dependencies [:nvim-lua/plenary.nvim]}
                            {1 :mrcjkb/rustaceanvim :ft [:rust] :version :^4}
                            {1 :saecki/crates.nvim
                             :config (fn []
                                       ((. (require :crates) :setup) {:null_ls {:enabled true
                                                                                :name :crates.nvim}
                                                                      :popup {:border :rounded}}))
                             :dependencies [:nvim-lua/plenary.nvim]
                             :version :v0.3.0}
                            {1 :j-hui/fidget.nvim
                             :config (fn []
                                       ((. (require :fidget) :setup)))}
                            {1 :mfussenegger/nvim-jdtls :ft [:java]}
                            {1 :mrcjkb/haskell-tools.nvim
                             :ft [:haskell :lhaskell :cabal :cabalproject]
                             :version :^3}])

;; rust
(vim.api.nvim_set_keymap :n :<m-d> :<cmd>RustOpenExternalDocs<Cr>
                         {:noremap true :silent true})
(tset lvim.builtin.which_key.mappings :C
      {:D ["<cmd>lua require'crates'.show_dependencies_popup()<cr>"
           "[crates] show dependencies"]
       :P ["<cmd>lua require'crates'.show_popup()<cr>" "[crates] show popup"]
       :c ["<cmd>RustLsp openCargo<Cr>" "Open Cargo"]
       :d ["<cmd>RustLsp debuggables<Cr>" :Debuggables]
       :f ["<cmd>lua require'crates'.show_features_popup()<cr>"
           "[crates] show features"]
       :i ["<cmd>lua require'crates'.show_crate_popup()<cr>"
           "[crates] show info"]
       :m ["<cmd>RustLsp expandMacro<Cr>" "Expand Macro"]
       :name :Rust
       :p ["<cmd>RustLsp parentModule<Cr>" "Parent Module"]
       :r ["<cmd>RustLsp runnables<Cr>" :Runnables]
       :t ["<cmd>RustLsp testables<cr>" "Cargo Test"]
       :v ["<cmd>RustLsp crateGraph<Cr>" "View Crate Graph"]
       :y ["<cmd>lua require'crates'.open_repository()<cr>"
           "[crates] open repository"]})


;; Any changes to lvim.lsp.automatic_configuration.skipped_servers must be followed by :LvimCacheReset to take effect.
(vim.list_extend lvim.lsp.automatic_configuration.skipped_servers
                 [:hls :clangd :metals :lua_ls :rust_analyzer :jdtls])
(local (ok-status Neo-solarized) (pcall require :NeoSolarized))
(when ok-status
  (Neo-solarized.setup {:enable_italics true
                        :on_highlights (fn [highlights colors]
                                         (set highlights.Visual
                                              {:bg colors.yellow
                                               :fg colors.None}))
                        :style :dark
                        :styles {:comments {:italic true}
                                 :functions {:bold true}
                                 :keywords {:italic true}
                                 :string {:italic true}
                                 :undercurl true
                                 :underline true
                                 :variables {}}
                        :terminal_colors false
                        :transparent false}))

;; (vim.api.nvim_buf_set_keymap buf :n :zo ":LTExpandCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :zc ":LTCollapseCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :zM ":LTCollapseAllCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :<CR> ":LTJumpCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :s ":LTJumpCalltreeSplit<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :v ":LTJumpCalltreeVSplit<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :t ":LTJumpCalltreeTab<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :f ":LTFocusCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :i ":LTHoverCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :d ":LTDetailsCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :S ":LTSwitchCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :H ":LTHideCalltree<CR>" opts)
;; (vim.api.nvim_buf_set_keymap buf :n :X ":LTCloseCalltree<CR>" opts)	
;;  configure the litee.nvim library
((. (require :litee.lib) :setup) {})
((. (require :litee.calltree) :setup) {})
((. (require :litee.bookmarks) :setup) {})	

(local lspconfig (require :lspconfig))
(tset (require :lspconfig.configs) :fennel_language_server
      {:default_config {:cmd [:/Users/wangyuwei/.cargo/bin/fennel-language-server]
                        :filetypes [:fennel]
                        :root_dir (lspconfig.util.root_pattern :fnl)
                        :settings {:fennel {:diagnostics {:globals [:vim :lvim]}
                                            :workspace {:library (vim.api.nvim_list_runtime_paths)}}}
                        :single_file_support true}})
(lspconfig.fennel_language_server.setup {})
