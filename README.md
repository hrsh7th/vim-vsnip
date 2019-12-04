# vim-vsnip

Support VSCode(LSP)'s snippet feature in vim.


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
