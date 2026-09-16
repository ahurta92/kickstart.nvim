-- palette.lua — a VSCode-style command palette.
--
-- Every custom action in this config registers itself here instead of
-- claiming a <leader> chord.  You reach all of them by NAME:
--
--     Ctrl+Shift+P   (or <leader>p if your terminal eats Ctrl+Shift)
--
-- Registering from a plugin file looks like:
--
--     require('custom.palette').register {
--       { category = 'Project', name = 'Open gecko source', run = function() ... end },
--     }
--
-- Entries are matched on category + name + desc, sorted most-recently-used
-- first (per session), then alphabetically.

local M = {}

---@class PaletteAction
---@field category string  short bucket shown in the left column ('Project', 'Git', ...)
---@field name string      what you actually type to find it
---@field desc? string     extra words folded into the fuzzy match, not displayed
---@field run fun()        what happens on <CR>

---@type PaletteAction[]
M.actions = {}

local slot = {} -- "category\0name" -> index in M.actions, so re-registering replaces
local used = {} -- "category\0name" -> tick, for most-recently-used ordering
local tick = 0

local function key_of(a) return (a.category or '') .. '\0' .. a.name end

--- Add actions to the palette. Idempotent: registering the same
--- category+name twice replaces the entry rather than duplicating it,
--- so re-sourcing a config file is safe.
---@param list PaletteAction[]
function M.register(list)
  for _, a in ipairs(list) do
    assert(type(a.name) == 'string', 'palette: action is missing a name')
    assert(type(a.run) == 'function', 'palette: action ' .. tostring(a.name) .. ' is missing run()')
    local k = key_of(a)
    if slot[k] then
      M.actions[slot[k]] = a
    else
      table.insert(M.actions, a)
      slot[k] = #M.actions
    end
  end
end

-- Most-recently-used first, then category, then name.
local function ordered()
  local out = {}
  for i, a in ipairs(M.actions) do
    out[i] = a
  end
  table.sort(out, function(x, y)
    local rx, ry = used[key_of(x)] or 0, used[key_of(y)] or 0
    if rx ~= ry then return rx > ry end
    if (x.category or '') ~= (y.category or '') then return (x.category or '') < (y.category or '') end
    return x.name < y.name
  end)
  return out
end

--- Open the palette.
function M.open()
  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local themes = require 'telescope.themes'
  local tactions = require 'telescope.actions'
  local tstate = require 'telescope.actions.state'
  local entry_display = require 'telescope.pickers.entry_display'

  local items = ordered()
  if #items == 0 then
    vim.notify('palette: nothing registered yet', vim.log.levels.WARN)
    return
  end

  local col = 0
  for _, a in ipairs(items) do
    col = math.max(col, vim.fn.strdisplaywidth(a.category or ''))
  end

  local displayer = entry_display.create {
    separator = ' │ ',
    items = { { width = col }, { remaining = true } },
  }

  pickers
    .new(themes.get_dropdown { previewer = false, layout_config = { width = 0.7, height = 0.65 } }, {
      prompt_title = 'Command Palette',
      finder = finders.new_table {
        results = items,
        entry_maker = function(a)
          return {
            value = a,
            ordinal = table.concat({ a.category or '', a.name, a.desc or '' }, ' '),
            display = function() return displayer { { a.category or '', 'TelescopeResultsComment' }, a.name } end,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(bufnr)
        tactions.select_default:replace(function()
          local entry = tstate.get_selected_entry()
          tactions.close(bufnr)
          if not entry then return end
          local a = entry.value
          tick = tick + 1
          used[key_of(a)] = tick
          -- Deferred: many actions open another picker, which cannot start
          -- while this one is still tearing down.
          vim.schedule(function()
            local ok, err = pcall(a.run)
            if not ok then vim.notify('palette: ' .. a.name .. ': ' .. tostring(err), vim.log.levels.ERROR) end
          end)
        end)
        return true
      end,
    })
    :find()
end

return M
