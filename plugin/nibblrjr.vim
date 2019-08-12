let s:endpoint = 'http://localhost:8888'
let s:api = s:endpoint . '/api/'
function! nibblrjr#Test()
    echo 'test3'
endfunction

function! GetJSON(url)
    return json_decode(system('curl --silent ' . a:url))
endfunction

echo GetJSON(s:api . 'command/list')
