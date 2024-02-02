-- lvim.builtin.lualine.options.theme = "NeoSolarized"


lvim.builtin.dap.active = true
lvim.colorscheme = "NeoSolarized"
lvim.format_on_save = false
vim.diagnostic.config({ virtual_text = true })

lvim.lsp.buffer_mappings.normal_mode['gl'] = { vim.lsp.buf.outgoing_calls, "outgoing_calls" }
lvim.lsp.buffer_mappings.normal_mode['gk'] = { vim.lsp.buf.incoming_calls, "incoming_calls" }
lvim.lsp.buffer_mappings.normal_mode['mh'] = { vim.lsp.buf.document_highlight, "hightlight" }
lvim.lsp.buffer_mappings.normal_mode['ml'] = { vim.lsp.buf.clear_references, "cancel hightlight" }

lvim.builtin.which_key.mappings["m"] = {
	name = "bookmark",
	c = { "<Cmd>LTCreateBookmark<CR>", "create bookmark" },
	n = { "<Cmd>LTCreateNotebook<CR>", "create notebook" },
	d = { "<Cmd>LTDeleteBookmark<CR>", "delete bookmark" },
	o = { "<Cmd>LTOpenNotebook<CR>", "open nodebook" },
}

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
vim.opt.foldtext =
[[substitute(getline(v:foldstart),'\\t',repeat('\ ',&tabstop),'g').'...'.trim(getline(v:foldend)) . ' (' . (v:foldend - v:foldstart + 1) . ' lines)']]
vim.opt.foldenable = false                      -- if this option is true and fold method option is other than normal, every time a document is opened everything will be folded.
vim.opt.foldlevel = 1


lvim.builtin.treesitter.highlight.enable = true

-- auto install treesitter parsers
lvim.builtin.treesitter.ensure_installed = { "cpp", "c", "lua" }

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
		pattern = { "scala", "sbt" },
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
	{
		'mrcjkb/rustaceanvim',
		version = '^4', -- Recommended
		ft = { 'rust' },
	},
	{
		"saecki/crates.nvim",
		version = "v0.3.0",
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("crates").setup {
				null_ls = {
					enabled = true,
					name = "crates.nvim",
				},
				popup = {
					border = "rounded",
				},
			}
		end,
	},
	{
		"j-hui/fidget.nvim",
		config = function()
			require("fidget").setup()
		end,
	},
	{
		"mfussenegger/nvim-jdtls",
		ft = { "java" }
	}

})
-- rust
vim.api.nvim_set_keymap("n", "<m-d>", "<cmd>RustOpenExternalDocs<Cr>", { noremap = true, silent = true })

lvim.builtin.which_key.mappings["C"] = {
  name = "Rust",
  r = { "<cmd>RustLsp runnables<Cr>", "Runnables" },
  t = { "<cmd>RustLsp testables<cr>", "Cargo Test" },
  m = { "<cmd>RustLsp expandMacro<Cr>", "Expand Macro" },
  c = { "<cmd>RustLsp openCargo<Cr>", "Open Cargo" },
  d = { "<cmd>RustLsp debuggables<Cr>", "Debuggables" },
  p = { "<cmd>RustLsp parentModule<Cr>", "Parent Module" },
  v = { "<cmd>RustLsp crateGraph<Cr>", "View Crate Graph" },
--  R = {
--    "<cmd>lua require('rust-tools/workspace_refresh')._reload_workspace_from_cargo_toml()<Cr>",
--    "Reload Workspace",
--  },
--  o = { "<cmd>RustOpenExternalDocs<Cr>", "Open External Docs" },
  y = { "<cmd>lua require'crates'.open_repository()<cr>", "[crates] open repository" },
  P = { "<cmd>lua require'crates'.show_popup()<cr>", "[crates] show popup" },
  i = { "<cmd>lua require'crates'.show_crate_popup()<cr>", "[crates] show info" },
  f = { "<cmd>lua require'crates'.show_features_popup()<cr>", "[crates] show features" },
  D = { "<cmd>lua require'crates'.show_dependencies_popup()<cr>", "[crates] show dependencies" },
}


-- Any changes to lvim.lsp.automatic_configuration.skipped_servers must be followed by :LvimCacheReset to take effect.
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, { "clangd", "metals", "lua_ls", "rust_analyzer", "jdtls" })
local ok_status, NeoSolarized = pcall(require, "NeoSolarized")
if ok_status then
	NeoSolarized.setup {
		style = "dark",          -- "dark" or "light"
		transparent = false,     -- true/false; Enable this to disable setting the background color
		terminal_colors = false, -- Configure the colors used when opening a `:terminal` in Neovim
		enable_italics = true,   -- Italics for different hightlight groups (eg. Statement, Condition, Comment, Include, etc.)
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
