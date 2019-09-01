if exists('g:loaded_snips')
  exit
endif
let g:loaded_snips = 1

let g:vsnip_snippet_dir = get(g:, 'vsnip_snippet_dir', expand('<sfile>:p:h') . '/../resource/snippets')
let g:vsnip_verbose = get(g:, 'vsnip_verbose', v:false)

inoremap <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>
snoremap <Plug>(vsnip-expand-or-jump) <Esc>:<C-u>call vsnip#expand_or_jump()<CR>

command! VsnipEdit call s:cmd_edit()
command! -range=% VsnipSelect call s:cmd_select(<range>)
command! -range=% VsnipCall call s:cmd_call(<range>)

augroup vsnip
  autocmd!
  autocmd! vsnip TextChanged * call s:on_text_changed()
  autocmd! vsnip TextChangedI * call s:on_text_changed()
  autocmd! vsnip TextChangedP * call s:on_text_changed()
augroup END

function! s:cmd_edit()
  let l:filepath = vsnip#snippet#get_filepath(&filetype)
  if empty(l:filepath)
    echoerr printf('filetype(%s): snippet file is not found.', &filetype)
  endif
  execute printf('tabedit %s', l:filepath)
endfunction

function! s:cmd_select(range)
  call vsnip#select(s:get_selected_text(a:range))
endfunction

function! s:cmd_call(range)
  let l:name = input('Snippet: ', '', 'customlist,vsnip#snippet#by_name_completion')
  let l:snippet = vsnip#snippet#find_by_name(l:name)
  if !empty(l:snippet)
    call vsnip#expand_force(s:get_target_range(a:range), l:snippet)
  endif
endfunction


function! s:on_text_changed()
  let l:session = vsnip#get_session()
  if vsnip#utils#get(l:session, ['state', 'running'], v:false)
    call l:session.on_text_changed()
  endif
endfunction

function! s:get_target_range(range)
  if a:range == 2
    let l:start = getpos("'<")
    let l:end = getpos("'>")

    if strlen(l:end[1]) < l:end[2]
      let l:end[2] = strlen(getline(l:end[1])) + 1
    endif

    return {
          \   'start': [l:start[1], l:start[2]],
          \   'end': [l:end[1], l:end[2]]
          \ }
  endif

  let l:word = expand('<cWORD>')
  let l:word_len = strlen(l:word)
  let l:text = getline('.')
  let l:i = col('.')
  while 0 <= l:i
    if l:text[l:i - 1 : l:word_len + 1] == l:word
      return {
            \ 'start': [line('.'), l:i],
            \ 'end': [line('.'), l:i + l:word_len + 1]
            \ }
    endif
    let l:i -= 1
  endwhile
  return ''
endfunction

