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
  let l:text = substitute(l:text, "\t", l:one_indent, 'g') " convert \t as one indent
  let l:text = substitute(l:text, "\n\\zs", l:base_indent, 'g') " add base_indent for all lines
  let l:text = substitute(l:text, "\n\\s*\\ze\\(\n\\|$\\)", "\n", 'g') " remove empty line's indent
  return l:text
endfunction

"
" vsnip#indent#trim_base_indent
"
function! vsnip#indent#trim_base_indent(text) abort
  let l:base_indent = ''
  for l:line in split(a:text, "\n", v:true)
    let l:indent = matchstr(l:line, '^\s*')
    if l:base_indent ==# '' || l:indent !=# '' && strlen(l:indent) < strlen(l:base_indent)
      let l:base_indent = l:indent
    endif
  endfor
  return substitute(a:text, "\\%(^\\|\n\\)\\zs\\V" . l:base_indent, '', 'g')
endfunction

