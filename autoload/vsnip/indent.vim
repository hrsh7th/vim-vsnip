"
" vsnip#indent#get_one_indent
"
function! vsnip#indent#get_one_indent() abort
  return !&expandtab ? "\t" : repeat(' ', &shiftwidth ? &shiftwidth : &tabstop)
endfunction

"
" vsnip#indent#get_base_indent
"
function! vsnip#indent#get_base_indent(text) abort
  return matchstr(a:text, '^\s*')
endfunction

"
" vsnip#indent#adjust_snippet_body
"
function! vsnip#indent#adjust_snippet_body(line, text) abort
  let l:one_indent = vsnip#indent#get_one_indent()
  let l:base_indent = vsnip#indent#get_base_indent(a:line)
  let l:text = a:text
  if l:one_indent !=# "\t"
    while match(l:text, "\\%(^\\|\n\\)\\s*\\zs\\t") != -1
      let l:text = substitute(l:text, "\\%(^\\|\n\\)\\s*\\zs\\t", l:one_indent, 'g') " convert \t as one indent
    endwhile
  endif
  let l:text = substitute(l:text, "\n\\zs", l:base_indent, 'g') " add base_indent for all lines
  let l:text = substitute(l:text, "\n\\s*\\ze\n", "\n", 'g') " remove empty line's indent
  return l:text
endfunction

"
" vsnip#indent#trim_base_indent
"
function! vsnip#indent#trim_base_indent(text) abort
  let l:is_char_wise = match(a:text, "\n$") == -1
  let l:text = substitute(a:text, "\n$", '', 'g')

  let l:is_first_line = v:true
  let l:base_indent = ''
  for l:line in split(l:text, "\n", v:true)
    " Ignore the first line when the text created as char-wise.
    if l:is_char_wise && l:is_first_line
      let l:is_first_line = v:false
      continue
    endif

    " Ignore empty line.
    if l:line ==# ''
      continue
    endif

    " Detect most minimum base indent.
    let l:indent = matchstr(l:line, '^\s*')
    if l:base_indent ==# '' || strlen(l:indent) < strlen(l:base_indent)
      let l:base_indent = l:indent
    endif
  endfor
  return substitute(l:text, "\\%(^\\|\n\\)\\zs\\V" . l:base_indent, '', 'g')
endfunction
