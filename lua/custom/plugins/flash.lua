-- flash.lua — jump to anything on screen by label.
--
--   s{chars}{label}   jump: type a couple of characters of the target, then
--                     the letter shown next to the match you want
--   S                 select a Treesitter node (function, block, argument)
--   d s… / y s…       operators take a flash jump as their motion
--   r / R             (after an operator) act on a remote spot, then return
--   f t F T           still work, with every match highlighted; f again = next
--
-- Surround moved to gs… (init.lua) to give flash the s key.
return {
  {
    'folke/flash.nvim',
    event = 'VeryLazy',
    opts = {},
    keys = {
      { 's', mode = { 'n', 'x', 'o' }, function() require('flash').jump() end, desc = 'Flash jump' },
      { 'S', mode = { 'n', 'x', 'o' }, function() require('flash').treesitter() end, desc = 'Flash select code block' },
      { 'r', mode = 'o', function() require('flash').remote() end, desc = 'Flash remote' },
      { 'R', mode = { 'o', 'x' }, function() require('flash').treesitter_search() end, desc = 'Flash search code blocks' },
    },
  },
}
