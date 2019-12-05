# vim-vsnip

Support VSCode(LSP)'s snippet feature in vim.

# Rerequirements.

- nvim
  - v0.4.0 or higher.
- vim
  - v8.l.0039 or higher.

# Usage.

### install.

You can use your favorite plugin managers to install this plugin.

```viml
" vim-plug.
Plug 'hrsh7th/vim-vsnip'

" dein.nvim
call dein#add('hrsh7th/vim-vsnip')

" NeoBundle.
NeoBundle 'hrsh7th/vim-vsnip'
```

### setting.

```viml
" You can use other key to expand snippet.
imap <expr> <Tab> vsnip#available() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
smap <expr> <Tab> vsnip#available() ? '<Plug>(vsnip-expand-or-jump)' : '<Tab>'
```

### create your own snippet.

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
      "\t}"
      "}"
    ],
    "description": "Class definition template."
  }
}
```

The snippet format was described in [here](https://code.visualstudio.com/docs/editor/userdefinedsnippets#_snippet-syntax) or [here](https://github.com/Microsoft/language-server-protocol/blob/master/snippetSyntax.md).


# DEMO

![vsnip-demo](https://user-images.githubusercontent.com/629908/70024306-0d1a3b00-15dd-11ea-87ec-d5c648b763ab.gif)


# Concept

- Standard features written in Pure Vim script.

- Support VSCode(LSP)'s snippet format.

- Some LSP client integration.
    - vim-lsp
    - LanguageClient-neovim
    - vim-lamp


# Documentation

See `./doc/vsnip.txt`


# TODO

- Improve snippet source file detection.
    - Should understand `package.json` [example](https://github.com/xabikos/vscode-react/blob/master/package.json#L22)
    - Should convert filetype to LSP's languageId.

- Builtin plugin integration.
    - vim-lsp
    - vim-lamp

- Support more features in VSCode(LSP) spec.
    - regex transform
    - choice

- Some other useful features.
    - feel free to send request.

