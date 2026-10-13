-- debug.lua
--
-- nvim-dap configured for C/C++/Rust (codelldb) and Python (debugpy),
-- with nvim-dap-ui side panels and inline virtual-text values.

---@module 'lazy'
---@type LazySpec
return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio', -- required by dap-ui
    'theHamsta/nvim-dap-virtual-text',
    'mason-org/mason.nvim',
    'jay-babu/mason-nvim-dap.nvim',
  },
  keys = {
    { '<F5>', function() require('dap').continue() end, desc = 'Debug: Start/Continue' },
    { '<F1>', function() require('dap').step_into() end, desc = 'Debug: Step Into' },
    { '<F2>', function() require('dap').step_over() end, desc = 'Debug: Step Over' },
    { '<F3>', function() require('dap').step_out() end, desc = 'Debug: Step Out' },
    { '<F4>', function() require('dap').restart() end, desc = 'Debug: Restart' },
    { '<leader>b', function() require('dap').toggle_breakpoint() end, desc = 'Debug: Toggle Breakpoint' },
    { '<leader>B', function() require('dap').set_breakpoint(vim.fn.input 'Breakpoint condition: ') end, desc = 'Debug: Conditional Breakpoint' },
    { '<F7>', function() require('dapui').toggle() end, desc = 'Debug: Toggle UI' },
    { '<leader>cdh', function() require('dap.ui.widgets').hover() end, desc = 'Debug: Hover value', mode = { 'n', 'v' } },
    { '<leader>cde', function() require('dap').repl.open() end, desc = 'Debug: REPL' },
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    require('mason-nvim-dap').setup {
      automatic_installation = true,
      handlers = {},
      ensure_installed = {
        'codelldb', -- C / C++ / Rust
        'python', -- debugpy
      },
    }

    require('nvim-dap-virtual-text').setup {}

    ---@diagnostic disable-next-line: missing-fields
    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      ---@diagnostic disable-next-line: missing-fields
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close

    -- codelldb adapter (C / C++ / Rust)
    dap.adapters.codelldb = {
      type = 'server',
      port = '${port}',
      executable = {
        command = vim.fn.exepath 'codelldb',
        args = { '--port', '${port}' },
      },
    }

    local cpp_config = {
      {
        name = 'Launch',
        type = 'codelldb',
        request = 'launch',
        program = function() return vim.fn.input('Path to executable: ', vim.fn.getcwd() .. '/build/', 'file') end,
        cwd = '${workspaceFolder}',
        stopOnEntry = false,
        args = {},
      },
      {
        name = 'Attach to process',
        type = 'codelldb',
        request = 'attach',
        pid = require('dap.utils').pick_process,
        args = {},
      },
    }
    dap.configurations.c = cpp_config
    dap.configurations.cpp = cpp_config
    dap.configurations.rust = cpp_config

    -- Python (debugpy) adapter and configuration are registered by
    -- mason-nvim-dap automatically when 'python' is in ensure_installed.
  end,
}
