function! snips#cursor#get_snippet_with_prefix(filetype)
 let l:definition = snips#snippet#get_definition(a:filetype)
 if empty(l:definition)
   return ['', {}]
 endif

 let l:line = getline('.')
 let l:col = min([col('.'), strlen(l:line)])
 let l:text = l:line[0 : l:col]
 for [l:prefix, l:idx] in items(l:definition['index'])
   if strlen(l:text) < strlen(l:prefix)
     continue
   endif
   if l:text[-strlen(l:prefix) : -1] ==# l:prefix
     return [l:prefix, l:definition['snippets'][l:idx]]
   endif
 endfor
 return ['', {}]
endfunction

