local registry = require "mason-registry"

local pkg_name = "haskell-language-server"
vim.g.haskell_tools = {
	---@type ToolsOpts
	tools = {
		-- ...
	},
	---@type HaskellLspClientOpts
	hls = {
		---@param client number The LSP client ID.
		---@param bufnr number The buffer number
		---@param ht HaskellTools = require('haskell-tools')
		on_attach = function(client, bufnr, ht)
			require("lvim.lsp").common_on_attach(client, bufnr)
		end,
		-- ...
	},
	---@type HTDapOpts
	dap = {
		-- ...
	},
}

if not registry.is_installed(pkg_name) then
	vim.notify_once(string.format("Installing [%s]", pkg_name), vim.log.levels.INFO)
	local pkg = registry.get_package(pkg_name)
	pkg:install():once("closed", function()
		if pkg:is_installed() then
			vim.schedule(function()
				vim.notify_once(string.format("Installation complete for [%s]", pkg_name),
					vim.log.levels.INFO)
			end)
		end
	end)
end

