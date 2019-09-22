# nibblrjr.vim

<p align="center">
  <img width="864" height="549" src="http://kirjava.xyz/nibblrjr.vim.gif">

  manipulate your bot commands remotely with vim ^_^
</p>

requires [nibblrjr 3.5.0](https://github.com/kirjavascript/nibblrjr) and **vim8**

## Install

### vim-plug

```vim
Plug 'kirjavascript/nibblrjr.vim'
```

then type `:PlugInstall`

### Vundle

```vim
Plugin 'kirjavascript/nibblrjr.vim'
```

then type `:PluginInstall`

### Pathogen

    git clone https://github.com/kirjavascript/nibblrjr.vim ~/.vim/bundle/nibblrjr.vim

## Run

type `:NibblrJr`

## Config

use a custom endpoint (default is `http://nibblr.pw`)

```vim
let g:nibblrjrURL = 'https://concrete.party/irc'
```
