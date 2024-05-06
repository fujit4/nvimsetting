-- settings -----------------------------------------------
vim.opt.number = true
vim.opt.relativenumber = true
-- vim.opt.shiftwidth = 4



-- plugin manager lazy ------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct

-- plugins ------------------------------------------------
require("lazy").setup({
	{ 'echasnovski/mini.nvim', version = '*' },
	{
		'nvim-telescope/telescope.nvim', tag = '0.1.4',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	{
		"nvim-telescope/telescope-file-browser.nvim",
		dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" }
	},
	{ "neovim/nvim-lspconfig"},
	-- {'hrsh7th/nvim-cmp', event = 'InsertEnter, CmdlineEnter'},
	{'hrsh7th/nvim-cmp', event = 'InsertEnter'},
	{'hrsh7th/cmp-nvim-lsp', event = 'InsertEnter'},
	{'hrsh7th/cmp-buffer', event = 'InsertEnter'},
	{'hrsh7th/cmp-nvim-lsp-signature-help', event = 'InsertEnter'},
	{'hrsh7th/cmp-nvim-lsp-document-symbol', event = 'InsertEnter'},
	{'hrsh7th/cmp-calc', event = 'InsertEnter'},
	{'onsails/lspkind.nvim', event = 'InsertEnter'},
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' }
	},
	{'Mofiqul/vscode.nvim'},
	{"lukas-reineke/indent-blankline.nvim", main = "ibl", opts = {}},
	-- {'kihachi2000/yash.nvim'},
	{'windwp/nvim-autopairs',  event = "InsertEnter",opts = {}},
})

-- mini
require("mini.comment").setup()
-- require("mini.surround").setup()

-- telescope
-- local builtin = require('telescope.builtin')
-- vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
-- vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
-- vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
-- vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- telescope file browser
-- require("telescope").load_extension "file_browser"
-- vim.api.nvim_set_keymap(
--   "n",
--   "<space>fb",
--   ":Telescope file_browser<CR>",
--   { noremap = true }
-- )

-- lsp by nvim-lspconfig
local lspconfig = require('lspconfig')
lspconfig.gopls.setup {}
lspconfig.lua_ls.setup({
  settings = {
    Lua = {
      runtime = {
        version = "LuaJIT",
        pathStrict = true,
        path = { "?.lua", "?/init.lua" },
      },
      workspace = {
        library = vim.list_extend(vim.api.nvim_get_runtime_file("lua", true), {
          "${3rd}/luv/library",
          "${3rd}/busted/library",
          "${3rd}/luassert/library",
        }),
        checkThirdParty = "Disable",
      },
    },
  },
})

local lspopts = { noremap=true, silent=true }
vim.keymap.set('n', '<space>e', vim.diagnostic.open_float, lspopts)

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local opts = {buffer = ev.buf}
    vim.bo[ev.buf].formatexpr = nil
    vim.bo[ev.buf].omnifunc = nil
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = ev.buf })
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})

-- imports and formatting
-- https://github.com/golang/tools/blob/master/gopls/doc/vim.md#imports-and-formatting
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
    local params = vim.lsp.util.make_range_params()
    params.context = {only = {"source.organizeImports"}}
    -- buf_request_sync defaults to a 1000ms timeout. Depending on your
    -- machine and codebase, you may want longer. Add an additional
    -- argument after params if you find that you have to write the file
    -- twice for changes to be saved.
    -- E.g., vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, 3000)
    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params)
    for cid, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          local enc = (vim.lsp.get_client_by_id(cid) or {}).offset_encoding or "utf-16"
          vim.lsp.util.apply_workspace_edit(r.edit, enc)
        end
      end
    end
    vim.lsp.buf.format({async = false})
  end
})

-- cmp
local cmp = require('cmp')
local lspkind = require('lspkind')

 cmp.setup({

   window = {
      completion = cmp.config.window.bordered({
        border = 'single'
    }),
      documentation = cmp.config.window.bordered({
        border = 'single'
    }),
   },

   mapping = cmp.mapping.preset.insert({
     ['<Tab>'] = cmp.mapping.select_next_item(),
     ['<S-Tab>'] = cmp.mapping.select_prev_item(),
     ['<C-b>'] = cmp.mapping.scroll_docs(-4),
     ['<C-f>'] = cmp.mapping.scroll_docs(4),
     ['<C-Space>'] = cmp.mapping.complete(),
     ['<C-e>'] = cmp.mapping.abort(),
     ['<CR>'] = cmp.mapping.confirm({ select = true }),
   }),

 formatting = {
   format = lspkind.cmp_format({
     mode = 'symbol',
     maxwidth = 50,
     ellipsis_char = '...',
   })
  },

 sources = cmp.config.sources({
   { name = 'nvim_lsp' },
   { name = 'nvim_lsp_signature_help' },
  }, {
   { name = 'buffer', keyword_length = 2 },
   { name = 'calc' },
   { name = 'path' },
  })
 })


local capabilities = require('cmp_nvim_lsp').default_capabilities()


-- color
vim.opt.termguicolors = true
vim.opt.background = 'dark'
require('vscode').load()

-- lualine
require('lualine').setup({
	options = {
		theme = 'auto',
	},
	sections = {
		lualine_c = {'filename' ,"vim.lsp.get_active_clients()[1].name" }
	},
})

-- indent-blankline
require("ibl").setup()
