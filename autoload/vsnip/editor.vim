function! vsnip#editor#open(bang, cmd) abort
  let l:candidates = vsnip#source#filetypes(bufnr('%'))
  if a:bang
    let l:idx = 1
  else
    let l:idx = inputlist(['Select type: '] + map(copy(l:candidates), { k, v -> printf('%s: %s', k + 1, v) }))
    if l:idx == 0
      return
    endif
  endif

  if !isdirectory(g:vsnip_snippet_dir)
    let l:prompt = printf('`%s` does not exists, create? y(es)/n(o): ', g:vsnip_snippet_dir)
    if index(['y', 'ye', 'yes'], input(l:prompt)) >= 0
      call mkdir(g:vsnip_snippet_dir, 'p')
    else
      return
    endif
  endif

  let l:filename = fnameescape(printf('%s/%s.json',
  \   g:vsnip_snippet_dir,
  \   l:candidates[l:idx - 1]
  \ ))

  call execute(a:cmd)
  set filetype=vsnip
  set buftype=acwrite
  augroup vsnip-filetype
    autocmd! BufWriteCmd <buffer> call s:save()
  augroup END

  let l:json = {}
  if filereadable(l:filename)
    try
      let l:json = readfile(l:filename)
      let l:json = type(l:json) == type([]) ? join(l:json, "\n") : l:json
      let l:json = json_decode(l:json)
    catch /.*/
      let l:json = {}
    endtry
  endif
  for [l:key, l:snippet] in reverse(items(l:json))
    call append(0, [
    \   'snippet(' . l:key . ') {',
    \   '	prefix: ' . json_encode(l:snippet.prefix),
    \   '} {'
    \ ] + map(copy(s:to_list(l:snippet.body)), '"	" . v:val') + [
    \   '}',
    \   ''
    \ ])
  endfor
  call VsnipSyntax(l:candidates[l:idx - 1])
endfunction

"
" save
"
function! s:save() abort
  " parse and save.
endfunction

"
" to_list
"
function! s:to_list(v) abort
  return type(a:v) == type([]) ? a:v : [a:v]
endfunction
