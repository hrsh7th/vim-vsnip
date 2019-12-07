"
" vsnip#edits#text_edit#apply
"
function! vsnip#edits#text_edit#apply(bufnr, edits) abort
  let l:edits = a:edits
  let l:edits = s:range(l:edits)
  let l:edits = s:sort(l:edits)
  let l:edits = s:overlap(l:edits)

  " apply edit.
  let l:position = {
        \   'line': line('.'),
        \   'character': col('.')
        \ }
  for l:edit in reverse(copy(l:edits))
    call s:edit(l:edit, l:position)
  endfor

  " adjust curops.
  call setpos('.', [a:bufnr, l:position.line, l:position.character])
endfunction

"
" s:edit
"
function! s:edit(edit, position) abort
  let l:start_line = getline(a:edit.range.start.line)
  let l:before_line = strcharpart(l:start_line, 0, a:edit.range.start.character - 1)
  let l:end_line = getline(a:edit.range.end.line)
  let l:after_line = strcharpart(l:end_line, a:edit.range.end.character - 1, strchars(l:end_line) - (a:edit.range.end.character - 1))

  let l:lines = split(a:edit.newText, "\n", v:true)
  let l:lines[0] = l:before_line . l:lines[0]
  let l:lines[-1] = l:lines[-1] . l:after_line

  let l:lines_len = len(l:lines)
  let l:range_len = a:edit.range.end.line - a:edit.range.start.line

  let l:total_lines = len(getline('^', '$'))

  " fix cursor pos
  if a:edit.range.end.line <= a:position.line
    if a:edit.range.end.line == a:position.line
      if a:position.character <= a:edit.range.end.character
        " TODO: Is this needed?
        " let a:position.character = a:edit.range.end.character
      else
        let a:position.character = a:position.character + strchars(l:lines[-1]) - strchars(l:end_line)
      endif
    endif

    let a:position.line += l:lines_len - l:range_len - 1
  endif

  " update or append.
  let l:i = 0
  while l:i < l:lines_len
    let l:lnum = a:edit.range.start.line + l:i
    if l:i <= l:range_len && l:i < l:total_lines
      if getline(l:lnum) !=# l:lines[l:i]
        call setline(l:lnum, l:lines[l:i])
      endif
    else
      call append(l:lnum - 1, l:lines[l:i])
    endif
    let l:i += 1
  endwhile

  " delete.
  if l:lines_len <= l:range_len
    let l:start = a:edit.range.end.line - (l:range_len - l:lines_len)
    let l:end = a:edit.range.end.line
    execute printf('normal! %s,%sdelete _', l:start, l:end)
  endif
endfunction

"
" s:range
"
function! s:range(edits) abort
  let l:edits = []
  for l:edit in a:edits
    let l:range = {
          \   'start': {
          \     'line': l:edit.range.start.line + 1,
          \     'character': l:edit.range.start.character + 1,
          \   },
          \   'end': {
          \     'line': l:edit.range.end.line + 1,
          \     'character': l:edit.range.end.character + 1,
          \   },
          \ }
    if l:range.start.line > l:range.end.line || (
          \   l:range.start.line == l:range.end.line &&
          \   l:range.start.character > l:range.end.character
          \ )
      let l:range = {
            \   'start': l:range.end,
            \   'end': l:range.start
            \ }
    endif
    call add(l:edits, {
          \   'range': l:range,
          \   'newText': l:edit.newText
          \ })
  endfor
  return l:edits
endfunction

"
" s:sort
"
function! s:sort(edits) abort
  function! s:compare(edit1, edit2) abort
    let l:diff = a:edit1.range.start.line - a:edit2.range.start.line
    if l:diff == 0
      return a:edit1.range.start.character - a:edit2.range.start.character
    endif
    return l:diff
  endfunction
  return sort(copy(a:edits), function('s:compare', [], {}))
endfunction

"
" s:overlap
"
function! s:overlap(edits) abort
  if len(a:edits) > 1
    let l:range = a:edits[0].range
    for l:edit in a:edits[1 : -1]
      if l:range.end.line > l:edit.range.start.line || (
            \   l:range.end.line == l:edit.range.start.line &&
            \   l:range.end.character > l:edit.range.start.character
            \ )
        throw 'vsnip#edits#text_edit#apply: range overlapped.'
      endif

      let l:range = l:edit.range
    endfor
  endif
  return a:edits
endfunction


