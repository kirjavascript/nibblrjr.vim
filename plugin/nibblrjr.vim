" ? / ~ commands
" s - vsplit
" support locking/starring
" ~ / ? / "> not working
" help
" check hashweb
" bump main version - say requirement

if v:version < 801
    echoe 'nibblrjr editor requires vim 8.1'
    finish
endif

let s:endpoint = get(g:, 'nibblrjrURL', 'http://nibblr.pw')
let s:password = ''

let s:help="nibblrjr command editor - " . s:endpoint ."
         \\n  o:open a:add D:delete l:lock s:star S:sudo
         \\n --------------------------------------------"
let s:helpLines = 3

function! nibblrjr#List()
    let l:list = s:GetJSON('command/list')
    if type(l:list) != v:t_list
        echom 'nibblrjr: no listing returned from ' . s:endpoint
        return
    endif

    vnew
    put=s:help
    keepjumps normal! ggddG

    for command in l:list
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
    syntax match Comment /\%3l-/
    syntax match String /\%1lnibblr/
    syntax match Constant /\%1ljr/
    syntax match Type /\%2l\(\S\):/

    noremap <buffer> <silent> o :call nibblrjr#Get()<cr>
    noremap <buffer> <silent> S :call nibblrjr#Sudo()<cr>
    noremap <buffer> <silent> D :call nibblrjr#Delete()<cr>
    noremap <buffer> <silent> a :call NibblrAdd()<cr>
endfunction

function! nibblrjr#Get()
    if line('.') > s:helpLines
        let l:name = s:GetCommandName()

        if bufwinnr(l:name) > 0
            enew
            silent execute 'file ' . l:name
        else
            silent execute 'edit ' . l:name
            keepjumps normal! ggdG
        endif

        let s:res = s:GetJSON('command/get/' . s:UrlEncode(l:name))

        if has_key(s:res, 'error')
            echo 'nibblrjr: ' . s:res.error
        else
            put = s:res.command
            keepjumps normal! ggdd
            let &modified = 0
            setlocal filetype=javascript
            setlocal buftype=acwrite
            setlocal noswapfile
            autocmd! BufWriteCmd <buffer> call nibblrjr#Set()
        endif
    endif
endfunction

function! nibblrjr#Set()
    let l:name = expand('%')
    let l:buf = join(getline(1, '$'), "\n")
    let l:obj = { 'command': l:buf }
    let s:res = s:PostJSON('command/set/' . s:UrlEncode(l:name), l:obj)
    if has_key(s:res, 'error')
        echo 'nibblrjr: ' . s:res.error
    else
        let &modified = 0
    endif
endfunction

function! nibblrjr#Delete()
    let l:name = s:GetCommandName()
    if line('.') > s:helpLines && confirm('are you sure you want to delete ' . l:name, "&Ok\n&Cancel") == 1

        let s:res = s:PostJSON('command/delete/' . s:UrlEncode(l:name), {})
        if has_key(s:res, 'error')
            echo 'nibblrjr: ' . s:res.error
        else
            setlocal modifiable
            normal! dd
            setlocal nomodifiable
        endif
    endif
endfunction

function! nibblrjr#Sudo()
    let l:password = inputsecret('password: ')
    normal! :<ESC>
    if len(l:password)
        echo 'nibblrjr: password changed'
        let s:password = l:password
    else
        echo 'nibblrjr: password not changed'
    endif
endfunction

function! s:GetCommandName()
    let l:name = getline('.')
    " strip everything after the first space
    return substitute(l:name, " .*", "", "")
endfunction

function! s:GetJSON(url)
    let l:url = s:endpoint . '/api/' . a:url
    return json_decode(system('curl --silent ' . l:url))
endfunction

function! s:PostJSON(url, obj)
    if len(s:password)
        let a:obj.password = s:password
    endif
    let l:url = s:endpoint . '/api/' . a:url
    let l:exec = 'curl -H "Content-Type: application/json" -s -d @- ' . l:url
    let json = system(l:exec, json_encode(a:obj))
    return json_decode(json)
endfunction

function! s:UrlEncode(string)
    let l:result = ""

    let l:characters = split(a:string, '.\zs')
    for l:character in l:characters
        let l:ascii_code = char2nr(l:character)
        if l:character == " "
            let l:result = l:result . "+"
        elseif (l:ascii_code >= 48 && l:ascii_code <= 57) || (l:ascii_code >= 65 && l:ascii_code <= 90) || (l:ascii_code >= 97 && l:ascii_code <= 122) || (l:character == "-" || l:character == "_" || l:character == "." || l:character == "~")
            let l:result = l:result . l:character
        else
            let i = 0
            while i < strlen(l:character)
                let byte = strpart(l:character, i, 1)
                let decimal = char2nr(byte)
                let l:result = l:result . "%" . printf("%02x", decimal)
                let i += 1
            endwhile
        endif
    endfor

    return l:result
endfunction

call nibblrjr#List()
