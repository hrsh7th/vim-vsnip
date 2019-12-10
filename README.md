# vim-vsnip

VSCode(LSP)'s snippet feature in vim.

vsnip can integrate some other plugins via [vim-vsnip-integ](https://github.com/hrsh7th/vim-vsnip-integ). (e.g. [vim-lsp](https://github.com/prabirshrestha/vim-lsp))


# DEMO

![vsnip-demo](https://user-images.githubusercontent.com/629908/70024306-0d1a3b00-15dd-11ea-87ec-d5c648b763ab.gif)


# Concept

- Standard features written in Pure Vim script.
- Support VSCode(LSP)'s snippet format.
- Some LSP client integration.


# Features

- VSCode's snippet format support.
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
imap <expr> <Tab> vsnip#available() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
smap <expr> <Tab> vsnip#available() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
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

