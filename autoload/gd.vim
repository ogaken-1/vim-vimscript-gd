function! gd#jump(word) abort
  if a:word =~# '^\%(\w\+#\)\+'
    call s:SearchAutoloadSymbol(a:word)
  elseif a:word =~# 's:\w\+'
    call s:SearchScriptLocalSymbol(a:word)
  elseif a:word =~# 'a:\w\+'
    call s:SearchFunctionArgumentSymbol(a:word)
  else
    normal! gd
    let @/ = a:word->printf('\V\<%s\>')
  endif
endfunction

const s:defcmd = '\%(\<function\>!\?\|\<let\>\|\<const\>\)'

function! s:SearchAutoloadSymbol(word) abort
  const fname = a:word
        \ ->matchstr('^\%(\w\+#\)\+')
        \ ->substitute('#', '/', 'g')
        \ ->substitute('/$', '', '')
        \ ->printf('autoload/%s.vim')
  const files = fname->globpath(&rtp, v:true, v:true)
  if files->len() ==# 1
    exe 'edit' files[0]
    call search(a:word->printf('\V'..s:defcmd..'\s\zs\<%s\>'))
    let @/ = a:word->printf('\V\<%s\>')
  endif
endfunction

function! s:SearchScriptLocalSymbol(word) abort
  call cursor(1, 1)
  call search(a:word->printf('\V'..s:defcmd..'\s\zs\<%s\>'))
  let @/ = a:word->printf('\V\<%s\>')
endfunction

function! s:SearchFunctionArgumentSymbol(word) abort
  const pattern = a:word
        \ ->matchstr('a:\zs\w\+')
        \ ->printf('\V\<function\>!\?\.\+\zs%s')
  call search(pattern, 'b')
  let @/ = a:word->matchstr('a:\zs\w\+')->printf('\V\<\%(a:\)\?%s\>')
endfunction
