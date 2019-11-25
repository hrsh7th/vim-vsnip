if exists('g:loaded_vsnip')
  finish
endif
let g:loaded_vsnip = 1

let g:vsnip_snippet_dir = expand('~/.vsnip')
let g:vsnip_snippet_dirs = get(g:, 'vsnip_snippet_dirs', [])
let g:vsnip_sync_delay = 100
let g:vsnip_namespace = 'snip_'
let g:vsnip_select_trigger = ' '
let g:vsnip_select_pattern = '\k\+'

