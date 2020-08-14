# vim-vsnip

VSCode(LSP)'s snippet feature in vim.


# Features

- Nested placeholders
  - You can define snippet like `console.log($1${2:, $1})$0`
- Nested snippet expansion
    - You can expand snippet even if you already activated other snippet (it will be merged as one snippet)
- Load snippet from VSCode extension
    - If you install VSCode extension via `Plug 'microsoft/vscode-python'`, vsnip will load those snippets.
- Support many LSP-client & completion-engine by [vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ)
    - LSP-client
      - [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
      - [vim-lsc](https://github.com/natebosch/vim-lsc)
      - [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)
      - [neovim built-in lsp](https://github.com/neovim/neovim)
      - [vim-lamp](https://github.com/hrsh7th/vim-lamp)
    - completion-engine
      - [deoplete.nvim](https://github.com/Shougo/deoplete.nvim)
      - [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim)
      - [vim-mucomplete](https://github.com/lifepillar/vim-mucomplete)
      - [completion-nvim](https://github.com/haorenW1025/completion-nvim)
- Vim script interpolation
    - You can use Vim script interpolation as `${VIM:...Vim script expression...}`.


# Concept

- Pure Vim script
- Support VSCode snippet format
- Provide integration with many plugins


# Usage

### 1. Install

You can use your favorite plugin managers to install this plugin.

```viml
Plug 'hrsh7th/vim-vsnip'
Plug 'hrsh7th/vim-vsnip-integ'

call dein#add('hrsh7th/vim-vsnip')
call dein#add('hrsh7th/vim-vsnip-integ')

NeoBundle 'hrsh7th/vim-vsnip'
NeoBundle 'hrsh7th/vim-vsnip-integ'
```


### 2. Setting

```viml
" NOTE: You can use other key to expand snippet.

" Expand
imap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'
smap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'

" Expand or jump
imap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
smap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'

" Jump forward or backward
imap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
smap <expr> <Tab>   vsnip#jumpable(1)   ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
imap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr> <S-Tab> vsnip#jumpable(-1)  ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'

" Select or cut text to use as $TM_SELECTED_TEXT in the next snippet.
" See https://github.com/hrsh7th/vim-vsnip/pull/50
nmap        s   <Plug>(vsnip-select-text)
xmap        s   <Plug>(vsnip-select-text)
smap        s   <Plug>(vsnip-select-text)
nmap        S   <Plug>(vsnip-cut-text)
xmap        S   <Plug>(vsnip-cut-text)
smap        S   <Plug>(vsnip-cut-text)

" If you want to use snippet for multiple filetypes, you can `g:vsip_filetypes` for it.
let g:vsnip_filetypes = {}
let g:vsnip_filetypes.javascriptreact = ['javascript']
let g:vsnip_filetypes.typescriptreact = ['typescript']
```


### 3. Create your own snippet

Snippet file will store to `g:vsnip_snippet_dir` per filetype.

1. Open some file (example: `Sample.js`)
2. Invoke `:VsnipOpen` command.
3. Edit snippet.

```json
{
  "Class": {
    "prefix": ["class"],
    "body": [
      "/**",
      " * @author ${VIM:\\$USER}",
      " */",
      "class $1 ${2:extends ${3:Parent} }{",
      "\tconstructor() {",
      "\t\t$0",
      "\t}",
      "}"
    ],
    "description": "Class definition template."
  }
}
```

The snippet format was described in [here](https://code.visualstudio.com/docs/editor/userdefinedsnippets#_snippet-syntax) or [here](https://github.com/Microsoft/language-server-protocol/blob/master/snippetSyntax.md).


# Development

### How to run test it?

You can run `npm run test` after install [vim-themis](https://github.com/thinca/vim-themis).


### How sync same tabstop placeholders?

1. compute the `user-diff` ... `s:Session.flush_changes`
2. reflect the `user-diff` to snippet ast ... `s:Snippet.follow`
3. reflect the `sync-diff` to buffer content ... `s:Snippet.sync & s:Session.flush_changes`


# DEMO

### LSP integration

<img src="https://user-images.githubusercontent.com/629908/90160819-3bd3ec80-ddcd-11ea-919b-577d7eb559a4.gif" width="480" alt="Nested snippet expansion" />

### `<Plug(vsnip-cut-text)` with `$TM_SELECTED_TEXT`

<img src="https://user-images.githubusercontent.com/629908/90157756-17761100-ddc9-11ea-843f-d8b0d529ac61.gif" width="480" alt="&lt;Plug&rt;(vsnip-cut-text) with $TM_SELECTED_TEXT" />
