# vim-vsnip

VSCode(LSP)'s snippet feature in vim/nvim.

# Features

- Nested placeholders
  - You can define snippet like `console.log($1${2:, $1})$0`
- Nested snippet expansion
  - You can expand snippet even if you already activated other snippet (it will be merged as one snippet)
- Load snippet from VSCode extension
  - If you install VSCode extension via `Plug 'golang/vscode-go'`, vsnip will load those snippets.
- Support many LSP-client & completion-engine by [vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ)
  - LSP-client
    - [vim-lsp](https://github.com/prabirshrestha/vim-lsp)
    - [vim-lsc](https://github.com/natebosch/vim-lsc)
    - [yegappan-lsp](https://github.com/yegappan/lsp)
    - [LanguageClient-neovim](https://github.com/autozimu/LanguageClient-neovim)
    - [neovim built-in lsp](https://github.com/neovim/neovim)
  - completion-engine
    - [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim)
    - [vim-mucomplete](https://github.com/lifepillar/vim-mucomplete)
    - [vimcomplete](https://github.com/girishji/vimcomplete)
    - [ddc.vim](https://github.com/Shougo/ddc.vim)
    - [vim-easycompletion](https://github.com/jayli/vim-easycomplete)
- Vim script interpolation
  - You can use Vim script interpolation as `${VIM:...Vim script expression...}`.
- SnipMate-like syntax support
  - Snippet files in SnipMate format with the extension `.snippets` can be load.
  - NOTE: Full compatibility is not guaranteed. It is intended to easily create user-defined snippets.

# Concept

- Pure Vim script
- Well tested (neovim/0.4.4, vim/8.0.1567)
- Support VSCode snippet format
- Provide integration with many plugins

# Related repository

[friendly-snippets](https://github.com/rafamadriz/friendly-snippets) - Set of preconfigured snippets for all kind of programming languages that integrates really well with [vim-vsnip](https://github.com/hrsh7th/vim-vsnip), so all users can benefit from them and not to worry about setting up snippets on their own.

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
nmap        S   <Plug>(vsnip-cut-text)
xmap        S   <Plug>(vsnip-cut-text)

" If you want to use snippet for multiple filetypes, you can `g:vsnip_filetypes` for it.
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

# Recipe

### $TM\_FILENAME\_BASE

You can insert the filename via `fname\<Plug>(vsnip-expand)`.

```json
{
  "filename": {
    "prefix": ["fname"],
    "body": "$TM_FILENAME_BASE"
  }
}
```

### Log $TM\_SELECTED\_TEXT

You can fill `$TM_SELECTED_TEXT` by `<Plug>(vsnip-select-text)` or `<Plug>(vsnip-cut-text)`.

```json
{
  "log": {
    "prefix": ["log"],
    "body": "console.log(${1:$TM_SELECTED_TEXT});"
  }
}
```

### Insert environment vars

You can insert value by Vim script expression.

```json
{
  "user": {
    "prefix": "username",
    "body": "${VIM:\\$USER}"
  }
}
```

### Insert UUID via python

You can insert UUID via python.

```json
{
  "uuid": {
    "prefix": "uuid",
    "body": [
      "${VIM:system('python -c \"import uuid, sys;sys.stdout.write(str(uuid.uuid4()))\"')}"
    ]
  }
}
```

NOTE: `$VIM` is only in vsnip. So that makes to lost the snippet portability.

# DEMO

### LSP integration

<img src="https://user-images.githubusercontent.com/629908/90160819-3bd3ec80-ddcd-11ea-919b-577d7eb559a4.gif" width="480" alt="Nested snippet expansion" />

### `<Plug(vsnip-cut-text)` with `$TM_SELECTED_TEXT`

<img src="https://user-images.githubusercontent.com/629908/90157756-17761100-ddc9-11ea-843f-d8b0d529ac61.gif" width="480" alt="&lt;Plug&rt;(vsnip-cut-text) with $TM_SELECTED_TEXT" />

# Development

### How to run test it?

You can run `npm run test` after install [vim-themis](https://github.com/thinca/vim-themis).

### How sync same tabstop placeholders?

1. compute the `user-diff` ... `s:Session.flush_changes`
2. reflect the `user-diff` to snippet ast ... `s:Snippet.follow`
3. reflect the `sync-diff` to buffer content ... `s:Snippet.sync & s:Session.flush_changes`
