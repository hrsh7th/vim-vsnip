# vim-vsnip

VSCode(LSP)'s snippet feature in vim.

vsnip can integrate some other plugins via [vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ). (e.g. [vim-lsp](https://github.com/prabirshrestha/vim-lsp))


# DEMO

![nested-snippet-expansion](https://user-images.githubusercontent.com/629908/76817423-1e165180-6846-11ea-95a1-d827afa744d8.gif)


# Concept

- Standard features written in Pure Vim script.
- Support VSCode(LSP)'s snippet format.
- Some LSP client integration.


# Features

- VSCode's snippet format support.
- Nested snippet expansion
    - You can expand snippet even if you already activated other snippet.
    - Those snippet are merged one snippeet and works fine.
- Load snippet from VSCode's extension.
    - You can load snippet via `Plug 'microsoft/vscode-python'` etc.
    - If you use `dein.nvim`, You should set `merged` flag to 0.
- Some LSP client integration.
    - You can find how to integrate those plugins in [here](https://github.com/hrsh7th/vim-vsnip-integ).


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
" You can use other key to expand snippet.
imap <expr> <C-j>   vsnip#available(1)  ? '<Plug>(vsnip-expand)'         : '<C-j>'
" Expand selected placeholder with <C-j> (see https://github.com/hrsh7th/vim-vsnip/pull/51)
smap <expr> <C-j>   vsnip#expandable()  ? '<Plug>(vsnip-expand)'         : '<C-j>'
imap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
" Jump to the next placeholder with <C-l>
smap <expr> <C-l>   vsnip#available(1)  ? '<Plug>(vsnip-expand-or-jump)' : '<C-l>'
imap <expr> <Tab>   vsnip#available(1)  ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
smap <expr> <Tab>   vsnip#available(1)  ? '<Plug>(vsnip-jump-next)'      : '<Tab>'
imap <expr> <S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
smap <expr> <S-Tab> vsnip#available(-1) ? '<Plug>(vsnip-jump-prev)'      : '<S-Tab>'
```

### 3. Create your own snippet

Snippet source file will store to `g:vsnip_snippet_dir` per filetype.

1. Open some file (example: `Sample.js`)
2. Invoke `:VsnipOpen` command.
3. Edit snippet.

```json
{
  "Class": {
    "prefix": ["class"],
    "body": [
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


# Documentation

See `./doc/vsnip.txt`


# Integration

- You can use [vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ)


# Why create vim-vsnip?

- I want to support VSCode(LSP)'s snippet format.
    - Some LSP client plugins has no snippet feature.
    - This plugin aims to integrate those plugins.
- I want to snippet plugin that written in Pure Vim script.
    - For example, `vim-lsp`, `vim-lsc` are written in Pure Vim script.
    - If snippet plugin needs `python`, `lua` etc, will breaks those plugins advantage.
- I want to study parser combinator.


# TODO

- Should convert filetype to LSP's languageId.
    - It's breaking change...
- Support more features in VSCode(LSP) spec.
    - regex transform
- Some other useful features.
    - feel free to send request.

