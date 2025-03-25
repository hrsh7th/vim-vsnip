local M = {}

local ok_parsers, ts_parsers = pcall( require, "nvim-treesitter.parsers" )
if not ok_parsers then
  ts_parsers = nil
end

local ok_utils, ts_utils = pcall( require, "nvim-treesitter.ts_utils" )
if not ok_utils then
  ts_utils = nil
end

function M.is_available ()
  return ok_parsers and ok_utils
end

function M.get_ft_at_cursor ( bufnr )
  if M.is_available() then
    local cur_node = ts_utils.get_node_at_cursor( vim.fn.bufwinid( bufnr ) )

    if cur_node then
      local parser = ts_parsers.get_parser( bufnr )
      local lang = parser:language_for_range( { cur_node:range() } ):lang()

      if ts_parsers.list[ lang ] ~= nil then
        return ts_parsers.list[ lang ].filetype or lang
      end
    end
  end

  return vim.bo[ bufnr ].filetype or ""
end

return M
