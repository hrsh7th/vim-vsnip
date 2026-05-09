local M = {}

local is_available = pcall( require, "nvim-treesitter.util" )

local function get_parser_filetype ( lang )
  if lang then

    -- NOTE: first element [ 1 ] is always the lang itself
    -- other element placed in random order
    -- XXX: unclear how to use this data, how to distinguish lang from filetype
    -- return vim.treesitter.language.get_filetypes( lang )[ 2 ] or lang

    return lang
  else
    return ""
  end
end

function M.get_ft_at_cursor ( bufnr )
  local filetypes = {
    filetype = "",
    injected_filetype = "",
  }

  if is_available then
    local cur_node = vim.treesitter.get_node( { bufnr = bufnr } )

    if cur_node then
      local parser = vim.treesitter.get_parser( bufnr )
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
