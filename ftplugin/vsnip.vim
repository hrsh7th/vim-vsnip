function! VsnipSyntax(...) abort
  call s:update(get(a:000, 0, getbufvar('%', 'vsnip_filetype', &filetype)))
endfunction

function! s:update(filetype) abort
  setlocal noexpandtab shiftwidth=2 tabstop=2

  call s:apply('runtime! syntax/json5.vim')
  call s:apply('syntax include @VsnipJSON syntax/json5.vim')

  for l:syntax_path in s:find_syntax_paths(a:filetype)
    try
      call s:apply('runtime! %s', l:syntax_path)
      call s:apply('syntax include @VsnipFileType %s', l:syntax_path)
    catch /.*/
    endtry
  endfor

  call s:apply('syntax cluster VsnipNode contains=VsnipPlaceholder,VsnipTabstop,VsnipVariable')
  call s:apply('syntax match VsnipPlaceholder "\${\d\+\%(:\%(.\{-}\)\?\)\?}" contained') 
  call s:apply('syntax match VsnipTabstop "\$\d\+" contained') 
  call s:apply('syntax match VsnipVariable "\$\h\w\+" contained') 

  call s:apply('syntax match VsnipSnippet "snippet"  nextgroup=VsnipSnippetName skipwhite')
  call s:apply('syntax region VsnipSnippetName start="(\_s*" end="\_s*)" keepend nextgroup=VsnipSnippetArgs skipwhite')
  call s:apply('syntax region VsnipSnippetArgs start="{\_s*" end="\_s*}" transparent keepend contains=@VsnipJSON nextgroup=VsnipSnippetBody skipwhite')
  call s:apply('syntax region VsnipSnippetBody matchgroup=VsnipSnippetBodyOpen start="{"  matchgroup=VsnipSnippetBodyClose end="}\ze\_\s*\%($\|snippet\)" keepend contains=@VsnipNode,@VsnipFileType')

  highlight! link VsnipSnippet Special
  highlight! link VsnipSnippetName String
  highlight! link VsnipPlaceholder Visual
  highlight! link VsnipTabstop Visual
  highlight! link VsnipVariable Visual
endfunction

"
" find_syntax_paths
"
function! s:find_syntax_paths(filetype) abort
  let l:syntax_paths = []
  for l:rtp in split(&runtimepath, ',')
    let l:syntax_path = printf('%s/syntax/%s.vim', l:rtp, a:filetype)
    if filereadable(l:syntax_path)
      call add(l:syntax_paths, l:syntax_path)
    endif
  endfor
  return l:syntax_paths
endfunction
"
" apply
"
function! s:apply(cmd, ...) abort
  let b:current_syntax = ''
  unlet b:current_syntax

  let g:main_syntax = ''
  unlet g:main_syntax

  execute call('printf', [a:cmd] + a:000)
endfunction


