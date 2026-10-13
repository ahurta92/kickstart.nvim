return {
  'Shatur/neovim-tasks',
  dependencies = { 'nvim-lua/plenary.nvim' },
  cmd = { 'Task' },
  keys = {
    { '<leader>cc', '<cmd>Task start cmake configure<cr>', desc = '[C]make [C]onfigure' },
    { '<leader>cb', '<cmd>Task start cmake build<cr>', desc = '[C]make [B]uild' },
    { '<leader>cr', '<cmd>Task start cmake run<cr>', desc = '[C]make [R]un' },
    { '<leader>cd', '<cmd>Task start cmake debug<cr>', desc = '[C]make [D]ebug' },
    { '<leader>ck', '<cmd>Task start cmake clean<cr>', desc = '[C]make Clean' },
    { '<leader>ct', '<cmd>Task set_module_param cmake target<cr>', desc = '[C]make [T]arget select' },
    { '<leader>cx', '<cmd>Task cancel<cr>', desc = '[C]make Cancel' },
  },
  config = function()
    local Path = require 'plenary.path'
    require('tasks').setup {
      default_params = {
        cmake = {
          cmd = 'cmake',
          build_type = 'Debug',
          build_kit = 'ninja',
          dap = {
            config = 'cpp',
            name = 'codelldb',
          },
          args = {
            configure = { '-D', 'CMAKE_EXPORT_COMPILE_COMMANDS=1' },
          },
          build_dir = tostring(Path:new('{cwd}', 'build', '{build_kit}', '{build_type}')), -- Build directory. The expressions `{cwd}`, `{build_kit}` and `{build_type}` will be expanded with the corresponding text values. Could be a function that return the path to the build directory.
          cmake_kits_file = nil, -- set path to JSON file containing cmake kits
          cmake_build_types_file = nil, -- set path to JSON file containing cmake kits
          clangd_cmdline = {
            'clangd',
            '--background-index',
            '--clang-tidy',
            '--header-insertion=never',
            '--completion-style=detailed',
            '--offset-encoding=utf-8',
            '--pch-storage=memory',
            '--cross-file-rename',
            '-j=4',
          }, --
        },
      },
      save_before_run = true,
    }
  end,
}
