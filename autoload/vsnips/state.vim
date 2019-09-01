function! vsnips#state#create(snippet)
  let l:state = {
        \ 'running': v:false,
        \ 'buffer': [],
        \ 'start_position': vsnips#utils#curpos(),
        \ 'lines': [],
        \ 'current_idx': -1,
        \ 'placeholders': [],
        \ }

  " create body
  let l:indent = vsnips#utils#get_indent()
  let l:level = strchars(substitute(matchstr(getline('.'), '^\s*'), l:indent, '_', 'g'))
  let l:body = join(a:snippet['body'], "\n")
  let l:body = substitute(l:body, "\t", l:indent, 'g')
  let l:body = substitute(l:body, "\n", "\n" . repeat(l:indent, l:level), 'g')
  let l:body = substitute(l:body, "\n\\s\\+\\ze\n", "\n", 'g')

  " resolve variables.
  let l:body = vsnips#syntax#variable#resolve(l:body)

  " resolve placeholders.
  let [l:body, l:placeholders] = vsnips#syntax#placeholder#resolve(l:state['start_position'], l:body)
  let l:state['placeholders'] = l:placeholders
  let l:state['lines'] = split(l:body, "\n", v:true)

  return l:state
endfunction

function! vsnips#state#sync(state, diff)
  if !s:is_valid_diff(a:diff)
    return a:state
  endif
  if !s:is_diff_in_snippet_range(a:state, a:diff)
    let a:state['running'] = v:false
    return a:state
  endif

  " update snippet lines.
  let a:state['lines'] = vsnips#utils#edit#replace_text(
        \   a:state['lines'],
        \   vsnips#utils#range#relative(a:state['start_position'], a:diff['range']),
        \   a:diff['lines']
        \ )

  let l:placeholders = vsnips#syntax#placeholder#by_order(a:state['placeholders'])

  " fix placeholder ranges after already modified placeholder.
  let l:target = {}
  let l:i = 0
  let l:j = len(l:placeholders)
  while l:i < len(l:placeholders)
    let l:p = l:placeholders[l:i]

    " relocate same lines.
    if !empty(l:target)
      if l:p['range']['start'][0] == l:target['range']['start'][0]
        let l:p['range']['start'][1] += l:shiftwidth
        let l:p['range']['end'][1] += l:shiftwidth
      else
        break
      endif
    endif

    " modified placeholder.
    if vsnips#utils#range#in(l:p['range'], a:diff['range'])
      let l:new_lines = vsnips#utils#edit#replace_text(
            \   split(l:p['text'], "\n", v:true),
            \   vsnips#utils#range#relative(l:p['range']['start'], a:diff['range']),
            \   a:diff['lines']
            \ )
      let l:new_text = join(l:new_lines, "\n")

      " TODO: support multi-line.
      let l:old_length = l:p['range']['end'][1] - l:p['range']['start'][1]
      let l:new_length = strlen(l:new_text)
      let l:shiftwidth = l:new_length - l:old_length
      let l:p['text'] = l:new_text
      let l:p['range']['end'][1] += l:shiftwidth
      let l:target = l:p
      let l:j = l:i + 1
    endif

    let l:i += 1
  endwhile

  " sync same tabstop placeholder.
  let l:in_sync = {}
  let l:same_lines = 0
  let l:edits = []
  while l:j < len(l:placeholders)
    let l:p = l:placeholders[l:j]

    let l:is_same_line_in_sync = !empty(l:in_sync) && l:p['range']['start'][0] == l:in_sync['range']['start'][0]

    if l:p['tabstop'] == l:target['tabstop']
      call add(l:edits, {
            \   'range': deepcopy(l:p['range']),
            \   'lines': l:new_lines
            \ })
      let l:p['text'] = l:target['text']
      let l:p['range']['end'][1] += l:shiftwidth
      let l:in_sync = l:p
    endif

    if l:is_same_line_in_sync
      let l:same_lines += 1
      let l:p['range']['start'][1] += l:shiftwidth * l:same_lines
      let l:p['range']['end'][1] += l:shiftwidth * l:same_lines
    else
      let l:same_lines = 0
    endif

    let l:j += 1
  endwhile

  function! s:apply_edits(edits, timer_id)
    for l:edit in reverse(a:edits)
      call vsnips#utils#edit#replace_buffer(l:edit['range'], l:edit['lines'])
    endfor
  endfunction
  call timer_start(0, function('s:apply_edits', [l:edits]), { 'repeat': 1 })

  return a:state
endfunction

function! s:is_valid_diff(diff)
  let l:has_range_length = vsnips#utils#range#has_length(a:diff['range'])
  let l:has_new_text = len(a:diff['lines']) > 1 || get(a:diff['lines'], 0, '') != ''
  return l:has_range_length || l:has_new_text
endfunction

function! s:is_diff_in_snippet_range(state, diff)
  let l:snippet_text = join(a:state['lines'], "\n")
  let l:snippet_range = {
        \   'start': a:state['start_position'],
        \   'end': vsnips#utils#text_index2buffer_pos(a:state['start_position'], strlen(l:snippet_text), l:snippet_text)
        \ }
  return vsnips#utils#range#in(l:snippet_range, a:diff['range'])
endfunction

