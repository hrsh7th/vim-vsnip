function! vsnip#state#create(start_position, snippet) abort
  let l:state = {
        \ 'running': v:false,
        \ 'buffer': [],
        \ 'start_position': a:start_position,
        \ 'lines': [],
        \ 'current_idx': -1,
        \ 'placeholders': [],
        \ }

  " create body
  let l:indent = vsnip#utils#get_indent()
  let l:indent_level = vsnip#utils#get_indent_level(getline('.'), l:indent)
  let l:body = join(a:snippet['body'], "\n")
  let l:body = substitute(l:body, "\t", l:indent, 'g')
  let l:body = substitute(l:body, "\n", "\n" . repeat(l:indent, l:indent_level), 'g')
  let l:body = substitute(l:body, "\n\\s\\+\\ze\n", "\n", 'g')

  " resolve variables.
  let l:body = vsnip#syntax#variable#resolve(l:body)

  " resolve placeholders.
  let [l:body, l:placeholders] = vsnip#syntax#placeholder#resolve(l:state['start_position'], l:body)
  let l:state['placeholders'] = l:placeholders
  let l:state['lines'] = split(l:body, "\n", v:true)

  return l:state
endfunction

"
" Sync on physical buffer edits.
"
" 1. Sync position and text states to modified physical buffer.
" 2. Create edits for sync same tabstop, and update position and text states.
"
function! vsnip#state#sync(session, diff) abort
  if !s:is_valid_diff(a:diff)
    return []
  endif

  if !vsnip#utils#range#in(a:session.get_snippet_range(), a:diff['range'])
    let a:session['state']['running'] = v:false
    return []
  endif

  " Update snippet lines.
  let a:session['state']['lines'] = vsnip#utils#edit#replace_text(
        \   a:session['state']['lines'],
        \   vsnip#utils#range#relative(a:session['state']['start_position'], a:diff['range']),
        \   a:diff['lines']
        \ )

  let l:placeholders = vsnip#syntax#placeholder#by_order(a:session['state']['placeholders'])

  " Fix already modified & moved placeholders.
  let l:target = {}
  let l:i = 0
  let l:j = len(l:placeholders)
  while l:i < len(l:placeholders)
    let l:p = l:placeholders[l:i]

    " Detects already moved placeholders.
    if !empty(l:target)
      if l:p['range']['start'][0] == l:target['range']['start'][0]
        let l:p['range']['start'][1] += l:shiftwidth
        let l:p['range']['end'][1] += l:shiftwidth
      else
        break
      endif
      let l:i += 1
      continue
    endif

    " If detect already modified placeholder, sync text & position in state.
    if vsnip#utils#range#in(l:p['range'], a:diff['range'])
      let l:new_lines = vsnip#utils#edit#replace_text(
            \   split(l:p['text'], "\n", v:true),
            \   vsnip#utils#range#relative(l:p['range']['start'], a:diff['range']),
            \   a:diff['lines']
            \ )
      let l:new_text = join(l:new_lines, "\n")

      " TODO: Truncate multi-line changes to one-line changes.
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

  " Sync same tabstop placeholders and create those edits.
  let l:in_sync = {}
  let l:same_line = 0
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
      let l:same_line += 1
      let l:p['range']['start'][1] += l:shiftwidth * l:same_line
      let l:p['range']['end'][1] += l:shiftwidth * l:same_line
    else
      let l:same_line = 0
    endif

    let l:j += 1
  endwhile

  return l:edits
endfunction

function! s:is_valid_diff(diff) abort
  let l:has_range_length = vsnip#utils#range#has_length(a:diff['range'])
  let l:has_new_text = len(a:diff['lines']) > 1 || get(a:diff['lines'], 0, '') !=# ''
  return vsnip#utils#range#valid(a:diff['range']) && l:has_range_length || l:has_new_text
endfunction

