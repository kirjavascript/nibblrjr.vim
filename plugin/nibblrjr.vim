" s - vsplit
" ~ / ? / "> not working
" help
" requires 3.3.0

if v:version < 801
    echoe 'nibblrjr editor requires vim 8.1'
    finish
endif

let s:endpoint = get(g:, 'nibblrjrURL', 'http://nibblr.pw')
let s:password = ''
let s:help="nibblrjr command editor - " . s:endpoint ."
         \\n o:open a:add D:delete l:lock s:star S:sudo
         \\n--------------------------------------------"
let s:helpLines = 3
let s:list = []

command NibblrJr call nibblrjr#List()
" call nibblrjr#List()

function! nibblrjr#List()
    let l:list = s:GetJSON('command/list')
    if type(l:list) != v:t_list
        echom 'nibblrjr: no listing returned from ' . s:endpoint
        return
    endif
    let s:list = l:list

    enew
    put=s:help
    keepjumps normal! ggddG

    for command in s:list
        put = s:RenderLine(command)
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
    noremap <buffer> <silent> l :call nibblrjr#Lock()<cr>
    noremap <buffer> <silent> s :call nibblrjr#Star()<cr>
    noremap <buffer> <silent> a :call nibblrjr#Add()<cr>
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

function! nibblrjr#Add()
    if line('.') < s:helpLines
        normal! jjj
    endif
    let l:name = input('new command name: ')
    " hack to clear the input prompt
    normal! :<ESC>
    let s:res = s:PostJSON('command/new/' . s:UrlEncode(l:name), {})
    if has_key(s:res, 'error')
        echo 'nibblrjr: ' . s:res.error
    else
        setlocal modifiable
        put = s:RenderLine({ 'name' : l:name})
        setlocal nomodifiable
    endif
endfunction

function! nibblrjr#Lock()
    if line('.') > s:helpLines
        let l:name = s:GetCommandName()
        for command in s:list
            if command.name == l:name
                let l:config = { 'locked' : s:Toggle(command.locked) }
                let s:res = s:PostJSON('command/set-config/' . s:UrlEncode(l:name), l:config)
                if has_key(s:res, 'error')
                    echo 'nibblrjr: ' . s:res.error
                else
                    let command.locked = s:Toggle(command.locked)
                    setlocal modifiable
                    put = s:RenderLine(command)
                    normal! kdd
                    setlocal nomodifiable
                endif
                break
            endif
        endfor
    endif
endfunction

function! nibblrjr#Star()
    if line('.') > s:helpLines
        let l:name = s:GetCommandName()
        for command in s:list
            if command.name == l:name
                let l:config = { 'starred' : s:Toggle(command.starred) }
                let s:res = s:PostJSON('command/set-config/' . s:UrlEncode(l:name), l:config)
                if has_key(s:res, 'error')
                    echo 'nibblrjr: ' . s:res.error
                else
                    let command.starred = s:Toggle(command.starred)
                    setlocal modifiable
                    put = s:RenderLine(command)
                    normal! kdd
                    setlocal nomodifiable
                endif
                break
            endif
        endfor
    endif
endfunction

function! nibblrjr#Sudo()
    let l:password = inputsecret('password: ')
    normal! :<ESC>
    if len(l:password) && l:password != s:password
        echo 'nibblrjr: password changed'
        let s:password = l:password
    else
        echo 'nibblrjr: password not changed'
    endif
endfunction

function! s:RenderLine(command)
    let l:line = a:command.name . repeat(' ', 44 - len(a:command.name))
    if has_key(a:command, 'starred') && a:command.starred
        let l:line .= '★'
    else
        let l:line .= ' '
    endif
    if has_key(a:command, 'locked') && a:command.locked
        let l:line .= ' 🔒'
    endif
    return l:line
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

function s:Toggle(var)
    return a:var ? v:false : v:true
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
