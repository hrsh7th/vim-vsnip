local M = {}

--- Checks if a file or directory exists.  @local
-- @param f: string represneting the file's realpath
-- @return boolean
local exists = function(f)
  if vim.loop.fs_stat(f) ~= nil then
    return true
  else
    return false
  end
end


--- Creates a new file. @local
-- @param f string represneting the file's realpath
-- @raise error if file didn't get created.
local touch = function(fullpath)
  vim.loop.fs_open(fullpath, "w+", 33188, function(err, fd)
    assert(not err, err)
    vim.loop.fs_close(fd, function(c_err, ok)
      assert(not c_err and ok, "create file failed")
    end)
  end)
end


--- Ensure a file exists. @local
-- convent wrapper that ensure that a file exists, otherwise
-- creates it
-- @param f: string represneting the file's realpath
-- @return file path
local ensure = function(f)
  if not exists(f) then touch(f) end
  return f
end


--- Gets the current buffer selected lines.  @local
-- @return array of lines from selected V range.
local get_lines = function()
  return vim.api.nvim_buf_get_lines(
    0, -- current buffer
    unpack(vim.api.nvim_buf_get_mark(0, "<")) - 1, -- start
    unpack(vim.api.nvim_buf_get_mark(0, ">")), -- end
    0) -- ??
end


--- Wraps lines with quotes. @local
-- @param lines array of strings
-- @return array of lines, each wrapped with quotes.
local wrap_lines = function (lines)
  return vim.tbl_map(function(v)
    return string.format([["%s"]], v) end,
  lines)
end



--- Process prefix. @local
-- @param prefix a string or strings operated by comma.
-- @return array
local process_prefix =  function(prefix)
  if prefix:gmatch(",") then
    return vim.fn.split(prefix, ",")
  else
    return {prefix}
  end
end



--- Prompt user for an input. @local
-- concatenate t & s and ask user for input.
-- @param t & sstring
-- @return string
-- @todo use floating window :D
local get_value = function(t, s)
  return vim.fn.input(string.format("%s %s:> ", t, s))
end



--- Get a filetype's snippet filepath.
-- Given a filetype, return its the file path and ensure it exists.
-- @param ft string
-- @return string: snippet filepath
local get_snippet_file = function(ft)
  local f = "json"
  local file = ensure(string.format("%s/%s.%s", vim.g.vsnip_snippet_dir, ft, f))
  return file
end



--- Create a new snippet table from opts or user input.
-- when a opts is complete it return valid snippet table.
-- @param opts table of `title`, `desc,` `prefix`, `body`
-- @return table string to be inserted in
M.create_snippet_entry = function(opts)
  local opt = opts or {}
  local title = opt.title or vim.fn.input("snippet title:> ")
  return {
    [title] = {
      description = opt.desc or get_value(title, "snippet description"),
      prefix = opt.prefix or process_prefix(get_value(title, "snippet prefix(es)")),
      body = opt.body or get_value(title, "snippet body"),
    }
  }
end



--- Get snippets from filetype
-- parses json file and returns lua table
-- @param ft string
-- @raise error vim when file can't be opend
-- @return table of ft snippets
M.get_snippets_for_ft = function(ft)
  return vim.fn.json_decode(vim.fn.readfile(get_snippet_file(ft)))
end



--- Update ft's snippets.
-- update filetype's snippet with new snippet
-- @param ft string: representing the filetype.
-- @param ns table: representing the new snippet to add.
-- @todo get rid of jq dependency, prettify output without it!.
-- @todo I don't like the fact it read, parse then write the file.
-- find a way to just append to file without breaking json.
M.update_snippets = function(ft, ns)
  -- get current snippets table
  local old = M.get_snippets_for_ft(vim.bo.filetype)
  -- extend the old snippet with the new snippet
  local str = vim.fn.json_encode(vim.tbl_extend("force", old, ns))
  -- format with jq
  local output = (function()
    local tmp = vim.fn.tempname()
    vim.fn.writefile({str}, tmp, "a")
    local cmd = string.format("jq . %s", tmp)
    return vim.fn.systemlist(cmd)
  end)()
  -- write output
  local file = get_snippet_file(ft)
  vim.fn.delete(file)
  vim.fn.writefile(output, file, "a")
end



--- Adds `snippet` to `ft` snippets file.
-- @param ft string: representing the filetype.
-- @param snippet table: representing the snippet
-- @param open boolean: whether to open the snippet file for editing.
-- @todo navigate to the new entry. this is important becuase the current way of parsing doesn't allow order.
M.add_snippet = function(ft, snippet, open)
  -- get file path and create it if doesn't exist.
  local file = get_snippet_file(ft)

  -- update the ft snippet file with the new snippet
  M.update_snippets(ft, snippet)

  if not open then
    vim.fn.echo("The new snippet has been add to Vsnip.")
  else
    vim.cmd(open .. ' ' .. file)
  end
end



--- Adds the currently selected lines to snippets file.
-- @param open string: the command to open snippet with
M.add_snippet_from_range = function(open)
  local snippet = M.create_snippet_entry({body = wrap_lines(get_lines())})
  M.add_snippet(vim.bo.filetype, snippet, open)
end


return M
