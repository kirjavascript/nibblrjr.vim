if v:version < 801
    echoe 'nibblrjr editor requires vim 8.1'
    finish
endif

let s:help="nibblrjr command editor - o:open a:add D:delete
         \\n-----------------------------------------------"
let s:helpLines = 2

let s:endpoint = 'http://localhost:8888'
let s:api = s:endpoint . '/api/'

function! nibblrjr#GetJSON(url)
    return json_decode(system('curl --silent ' . a:url))
endfunction

function! nibblrjr#List()
    enew
    put=s:help
    keepjumps normal! ggddG
    for command in nibblrjr#GetJSON(s:api . 'command/list')
        put = command.name . repeat('-', 39 - len(command.name))
    endfor
    keepjumps normal! gg

    let &modified = 0
    setlocal buftype=nofile
    setlocal noswapfile
    setlocal nowrap
    setlocal nomodifiable

    set filetype=nibblrjr
    syntax match Type /★/
    syntax match Include /🔒/
    syntax match Operator /^\(\S*\)/
    syntax match Comment /\%2l-/
    syntax match String /\%1lnibblr/
    syntax match Constant /\%1ljr/
    syntax match Type /\%1l\(\S\):/

    noremap <buffer> <silent> o :call nibblrjr#Get()<cr>
    noremap <buffer> <silent> a :call NibblrAdd()<cr>
    noremap <buffer> <silent> D :call NibblrDelete()<cr>
endfunction

function! nibblrjr#Get()

endfunction

call nibblrjr#List()
