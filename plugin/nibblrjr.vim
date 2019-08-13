if v:version < 801
    echoe 'nibblrjr editor requires vim 8.1'
    finish
endif

let s:help="nibblrjr command editor - o:open a:add D:delete
         \\n-----------------------------------------------"
let s:helpLines = 2

let s:endpoint = 'http://localhost:8888'
let s:api = s:endpoint . '/api/'

function! nibblrjr#List()
    enew
    put=s:help
    keepjumps normal! ggddG
    for command in nibblrjr#GetJSON(s:api . 'command/list')
        let l:line = command.name . repeat(' ', 44 - len(command.name))
        if has_key(command, 'starred') && command.starred
            let l:line .= '★'
        else
            let l:line .= ' '
        endif
        if has_key(command, 'locked') && command.locked
            let l:line .= ' 🔒'
        endif
        put = l:line
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
    if line('.') > s:helpLines
        let l:name = getline('.')
        " strip everything after the first space
        let l:name = substitute(l:name, " .*", "", "")

        if bufwinnr(l:name) > 0
            enew
            silent execute 'file ' . l:name
        else
            silent execute 'edit ' . l:name
            keepjumps normal! ggdG
        endif

        put = nibblrjr#GetJSON(s:api . 'command/get/' . UrlEncode(l:name)).command
        keepjumps normal! ggdd
        let &modified = 0
        setlocal filetype=javascript
        setlocal buftype=acwrite
        setlocal noswapfile
        autocmd! BufWriteCmd <buffer> call NibblrSet()
    endif
endfunction

call nibblrjr#List()

function! nibblrjr#GetJSON(url)
    return json_decode(system('curl --silent ' . a:url))
endfunction

function! nibblrjr#UrlEncode(string)
    let result = ""

    let characters = split(a:string, '.\zs')
    for character in characters
        let ascii_code = char2nr(a:character)
        if character == " "
            let result = result . "+"
        elseif (ascii_code >= 48 && ascii_code <= 57) || (ascii_code >= 65 && ascii_code <= 90) || (ascii_code >= 97 && ascii_code <= 122) || (a:character == "-" || a:character == "_" || a:character == "." || a:character == "~")
            let result = result . character
        else
            let i = 0
            while i < strlen(character)
                let byte = strpart(character, i, 1)
                let decimal = char2nr(byte)
                let result = result . "%" . printf("%02x", decimal)
                let i += 1
            endwhile
        endif
    endfor

    return result
endfunction
