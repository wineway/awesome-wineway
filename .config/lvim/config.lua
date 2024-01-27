-- lvim.builtin.lualine.options.theme = "NeoSolarized"

vim.opt.tabstop = 8
vim.opt.shiftwidth = 8

lvim.builtin.dap.active = true
lvim.colorscheme = "NeoSolarized"
lvim.format_on_save = false
vim.diagnostic.config({ virtual_text = true })

lvim.lsp.buffer_mappings.normal_mode['gl'] = { vim.lsp.buf.outgoing_calls, "outgoing_calls" }
lvim.lsp.buffer_mappings.normal_mode['gk'] = { vim.lsp.buf.incoming_calls, "incoming_calls" }
lvim.lsp.buffer_mappings.normal_mode['mh'] = { vim.lsp.buf.document_highlight, "hightlight" }
lvim.lsp.buffer_mappings.normal_mode['ml'] = { vim.lsp.buf.clear_references, "cancel hightlight" }
-- lvim.lsp.buffer_mappings.normal_mode['mf'] = { require('telescope.builtin').lsp_references, "reference" }
lvim.keys.normal_mode['<leader>mc'] = "<Cmd>LTCreateBookmark<CR>"
lvim.keys.normal_mode['<leader>mn'] = "<Cmd>LTCreateNotebook<CR>"
lvim.keys.normal_mode['<leader>md'] = "<Cmd>LTDeleteBookmark<CR>"
lvim.keys.normal_mode['<leader>mo'] = "<Cmd>LTOpenNotebook<CR>"

-- gq - format code
-- zc - Close (fold) the current fold under the cursor.
-- zo - Open (unfold) the current fold under the cursor.
-- za - Toggle between closing and opening the fold under the cursor.
-- zR - Open all folds in the current buffer.
-- zM - Close all folds in the current buffer .
-- folding powered by treesitter
-- https://github.com/nvim-treesitter/nvim-treesitter#folding
-- look for foldenable: https://github.com/neovim/neovim/blob/master/src/nvim/options.lua
-- Vim cheatsheet, look for folds keys: https://devhints.io/vim
vim.opt.foldmethod = "expr"                     -- default is "normal"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()" -- default is ""
vim.opt.foldenable = false                      -- if this option is true and fold method option is other than normal, every time a document is opened everything will be folded.


lvim.builtin.treesitter.highlight.enable = true

-- auto install treesitter parsers
lvim.builtin.treesitter.ensure_installed = { "cpp", "c" }

-- scala
-- function to display metals status in the statusline
local function metals_status()
	local status = vim.g["metals_status"]
	if status == nil then
		return ""
	else
		return status
	end
end

local components = require("lvim.core.lualine.components")
lvim.builtin.lualine.sections.lualine_c = {
	-- NOTE: There is no way to append a component, so we need to include the components
	-- here that are already supplied by lunarvim in `lualine_c`
	components.diff,
	components.python_env,
	metals_status,
}

lvim.builtin.which_key.mappings["M"] = {
	name = "Metals",
	u = { "<Cmd>MetalsUpdate<CR>", "Update Metals" },
	i = { "<Cmd>MetalsInfo<CR>", "Metals Info" },
	r = { "<Cmd>MetalsRestartBuild<CR>", "Restart Build Server" },
	d = { "<Cmd>MetalsRunDoctor<CR>", "Metals Doctor" },
}

local metals_configs = function()
        local lvim_lsp = require("lvim.lsp")
        local metals_config = require("metals").bare_config()
        metals_config.on_init = lvim_lsp.common_on_init
        metals_config.on_exit = lvim_lsp.common_on_exit
        metals_config.capabilities = lvim_lsp.common_capabilities()
        metals_config.on_attach = function(client, bufnr)
                lvim_lsp.common_on_attach(client, bufnr)
                vim.keymap.set("n", "<leader>gd", vim.lsp.buf.format)
                require("metals").setup_dap()
        end
        metals_config.settings = {
                superMethodLensesEnabled = true,
                showImplicitArguments = true,
                showInferredType = true,
                showImplicitConversionsAndClasses = true,
                excludedPackages = {},
        }
        metals_config.init_options.statusBarProvider = false
        vim.api.nvim_create_autocmd("FileType", {
                pattern = { "scala", "sbt", "java" },
                callback = function() require("metals").initialize_or_attach(metals_config) end,
                group = vim.api.nvim_create_augroup("nvim-metals", { clear = true }),
        })
end

-- Additional Plugins
table.insert(lvim.plugins, {
        "p00f/clangd_extensions.nvim",
        {
                "Tsuzat/NeoSolarized.nvim",
                lazy = false, -- make sure we load this during startup if it is your main colorscheme
                priority = 1000, -- make sure to load this before all the other start plugins
                config = function()
                        vim.cmd [[ colorscheme NeoSolarized ]]
                end
        },
        "ldelossa/litee.nvim",
        "ldelossa/litee-calltree.nvim",
        "ldelossa/litee-bookmarks.nvim",
        "kevinhwang91/nvim-bqf",
        "nvim-lua/plenary.nvim",
        {
                "scalameta/nvim-metals",
                dependencies = {
                        "nvim-lua/plenary.nvim",
                },
                config = function()
                        metals_configs()
                end,
        },
})

vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "clangd", "metals" })

-- some settings can only passed as commandline flags, see `clangd --help`
local clangd_flags = {
        "--background-index",
        "--fallback-style=Google",
        "--all-scopes-completion",
        "--clang-tidy",
        "--log=error",
        "--completion-style=detailed",
        "--pch-storage=memory", -- could also be disk
        "--enable-config",    -- clangd 11+ supports reading from .clangd configuration file
        "--offset-encoding=utf-16", --temporary fix for null-ls
        -- "--limit-references=1000",
        -- "--limit-resutls=1000",
        -- "--malloc-trim",
        -- "--clang-tidy-checks=-*,llvm-*,clang-analyzer-*,modernize-*,-modernize-use-trailing-return-type",
        -- "--header-insertion=never",
        -- "--query-driver=<list-of-white-listed-complers>"
}

local provider = "clangd"

local custom_on_attach = function(client, bufnr)
        require("lvim.lsp").common_on_attach(client, bufnr)

        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "<leader>lh", "<cmd>ClangdSwitchSourceHeader<cr>", opts)
        vim.keymap.set("x", "<leader>lA", "<cmd>ClangdAST<cr>", opts)
        vim.keymap.set("n", "<leader>lH", "<cmd>ClangdTypeHierarchy<cr>", opts)
        vim.keymap.set("n", "<leader>lt", "<cmd>ClangdSymbolInfo<cr>", opts)
        vim.keymap.set("n", "<leader>lm", "<cmd>ClangdMemoryUsage<cr>", opts)

        require("clangd_extensions.inlay_hints").setup_autocmd()
        require("clangd_extensions.inlay_hints").set_inlay_hints()
end

local status_ok, project_config = pcall(require, "rhel.clangd_wrl")
if status_ok then
        clangd_flags = vim.tbl_deep_extend("keep", project_config, clangd_flags)
end

local custom_on_init = function(client, bufnr)
        require("lvim.lsp").common_on_init(client, bufnr)
        require("clangd_extensions.config").setup {}
        -- require("clangd_extensions.ast").init()
        vim.cmd [[
  command ClangdToggleInlayHints lua require('clangd_extensions.inlay_hints').toggle_inlay_hints()
  command -range ClangdAST lua require('clangd_extensions.ast').display_ast(<line1>, <line2>)
  command ClangdTypeHierarchy lua require('clangd_extensions.type_hierarchy').show_hierarchy()
  command ClangdSymbolInfo lua require('clangd_extensions.symbol_info').show_symbol_info()
  command -nargs=? -complete=customlist,s:memuse_compl ClangdMemoryUsage lua require('clangd_extensions.memory_usage').show_memory_usage('<args>' == 'expand_preamble')
  ]]
end

local opts = {
        cmd = { provider, unpack(clangd_flags) },
        on_attach = custom_on_attach,
        on_init = custom_on_init,
}

require("lvim.lsp.manager").setup("clangd", opts)

-- install codelldb with :MasonInstall codelldb
-- configure nvim-dap (codelldb)
lvim.builtin.dap.on_config_done = function(dap)
        dap.adapters.codelldb = {
                type = "server",
                port = "${port}",
                executable = {
                        -- provide the absolute path for `codelldb` command if not using the one installed using `mason.nvim`
                        command = "codelldb",
                        args = { "--port", "${port}" },

                        -- On windows you may have to uncomment this:
                        -- detached = false,
                },
        }

        dap.configurations.cpp = {
                {
                        name = "Launch file",
                        type = "codelldb",
                        request = "launch",
                        program = function()
                                local path
                                vim.ui.input({ prompt = "Path to executable: ", default = vim.loop.cwd() .. "/build/" },
                                        function(input)
                                                path = input
                                        end)
                                vim.cmd [[redraw]]
                                return path
                        end,
                        cwd = "${workspaceFolder}",
                        stopOnEntry = false,
                },
        }

        dap.configurations.c = dap.configurations.cpp
end

local ok_status, NeoSolarized = pcall(require, "NeoSolarized")
if ok_status then
        NeoSolarized.setup {
                style = "dark", -- "dark" or "light"
                transparent = false, -- true/false; Enable this to disable setting the background color
                terminal_colors = false, -- Configure the colors used when opening a `:terminal` in Neovim
                enable_italics = true, -- Italics for different hightlight groups (eg. Statement, Condition, Comment, Include, etc.)
                styles = {
                        -- Style to be applied to different syntax groups
                        comments = { italic = true },
                        keywords = { italic = true },
                        functions = { bold = true },
                        variables = {},
                        string = { italic = true },
                        underline = true, -- true/false; for global underline
                        undercurl = true, -- true/false; for global undercurl
                },
                -- Add specific hightlight groups
                on_highlights = function(highlights, colors)
                        highlights.Visual = { bg = colors.yellow, fg = colors.None }
                end,
        }
end

--    vim.api.nvim_buf_set_keymap(buf, "n", "zo", ":LTExpandCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "zc", ":LTCollapseCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "zM", ":LTCollapseAllCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "<CR>", ":LTJumpCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "s", ":LTJumpCalltreeSplit<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "v", ":LTJumpCalltreeVSplit<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "t", ":LTJumpCalltreeTab<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "f", ":LTFocusCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "i", ":LTHoverCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "d", ":LTDetailsCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "S", ":LTSwitchCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "H", ":LTHideCalltree<CR>", opts)
--    vim.api.nvim_buf_set_keymap(buf, "n", "X", ":LTCloseCalltree<CR>", opts)
-- configure the litee.nvim library
require('litee.lib').setup({})
-- configure litee-calltree.nvim
require('litee.calltree').setup({})
-- configure litee-bookmarks.nvim
require('litee.bookmarks').setup({})
