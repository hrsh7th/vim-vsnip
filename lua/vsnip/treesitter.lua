local M = {}

local ok_parsers, ts_parsers = pcall( require, "nvim-treesitter.parsers" )
if not ok_parsers then
  ts_parsers = nil
end

local ok_utils, ts_utils = pcall( require, "nvim-treesitter.ts_utils" )
if not ok_utils then
  ts_utils = nil
end

local function get_parser_filetype ( lang )
  if lang and ts_parsers.list[ lang ] then
    return ts_parsers.list[ lang ].filetype or lang
  else
    return ""
  end
end

local function is_available ()
  return ok_parsers and ok_utils
end

function M.get_ft_at_cursor ( bufnr )
  local filetypes = {
    filetype = "",
    injected_filetype = "",
  }

  if is_available() then
    local cur_node = ts_utils.get_node_at_cursor( vim.fn.bufwinid( bufnr ) )

    if cur_node then
      local parser = ts_parsers.get_parser( bufnr )
      local language_tree_at_cursor = parser:language_for_range( { cur_node:range() } )
      local language_at_cursor = language_tree_at_cursor:lang()

      local filetype = get_parser_filetype( language_at_cursor )

      if filetype ~= "" then
        filetypes.filetype = filetype

        local parent_language_tree = language_tree_at_cursor:parent()

        if parent_language_tree then
          local parent_language = parent_language_tree:lang()
          local parent_filetype = get_parser_filetype( parent_language )

          if parent_filetype ~= "" then
            filetypes.injected_filetype = parent_filetype .. "/" .. filetype
          end
        end

        return filetypes
      end
    end
  end

  filetypes.filetype = vim.bo[ bufnr ].filetype or ""

  return filetypes
end

return M
