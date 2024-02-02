local registry = require "mason-registry"
local pkg_name = "jdtls"

local start_lsp = function()
	local function resolve_lsp_bin_path(bin)
		local path = require "mason-core.path"
		return path.bin_prefix(bin)
	end

	local path = require('jdtls.path')
	local function find_root(markers, bufname)
		bufname = bufname or vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
		local dirname = vim.fn.fnamemodify(bufname, ':p:h')
		local getparent = function(p)
			return vim.fn.fnamemodify(p, ':h')
		end
		local contains_marks = function(name)
			for _, marker in ipairs(markers) do
				if vim.loop.fs_stat(path.join(name, marker)) then
					return true
				end
			end
		end
		while getparent(dirname) ~= dirname do
			if contains_marks(dirname) then
				if not contains_marks(getparent(dirname)) then
					return dirname
				end
			end
			dirname = getparent(dirname)
		end
	end

	-- Setup Capabilities
	local capabilities = require("lvim.lsp").common_capabilities()
	local extendedClientCapabilities = require(pkg_name).extendedClientCapabilities
	extendedClientCapabilities.resolveAdditionalTextEditsSupport = true
	local config = {
		cmd = { resolve_lsp_bin_path(pkg_name) },
		root_dir = find_root({ 'pom.xml' }),
		capabilities = capabilities,
		init_options = {
			extendedClientCapabilities = extendedClientCapabilities,
		},
		signatureHelp = { enabled = true },
		settings = {
			java = {
				maven = {
					downloadSources = true,
				},
				eclipse = {
					downloadSources = true,
				},
				implementationsCodeLens = {
					enabled = true,
				},
				referencesCodeLens = {
					enabled = true,
				},
				references = {
					includeDecompiledSources = true,
				},
				inlayHints = {
					parameterNames = {
						enabled = "all", -- literals, all, none
					},
				},
				configuration = {
					updateBuildConfiguration = "automatic",

					references = {
						includeDecompiledSources = true,
					},
				},
				import = {
					maven = {
						enabled = true
					}
				},
			}
		},
		on_attach = function(client, bufnr)
			require("lvim.lsp").common_on_attach(client, bufnr)
		end,
	}

	vim.api.nvim_create_autocmd({ "BufWritePost" }, {
		pattern = { "*.java" },
		callback = function()
			local _, _ = pcall(vim.lsp.codelens.refresh)
		end,
	})

	require('jdtls').start_or_attach(config)
end

if not registry.is_installed(pkg_name) then
	local pkg = registry.get_package(pkg_name)
	pkg:install():once("closed", function()
		if pkg:is_installed() then
			vim.schedule(function()
				vim.notify_once(string.format("Installation complete for [%s]", pkg_name),
					vim.log.levels.INFO)
				start_lsp()
			end)
		end
	end)
else
	start_lsp()
end

