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
        \ ?? &l:buftype ==# ''
        \ ? fname->globpath(s:FindRoot(bufname(), '.git'), v:true, v:true)
        \ : []
  if files->len() ==# 1
    exe 'edit' files[0]
    call search(a:word->printf('\V'..s:defcmd..'\s\zs\<%s\>'))
    let @/ = a:word->printf('\V\<%s\>')
  endif
endfunction

function! s:FindRoot(path, pattern) abort
  const start = a:path->isdirectory() ? a:path : a:path->fnamemodify(':p:h')
  let dir = start
  while dir !=# '/'
        \ && dir->readdir({ fname -> fname =~# a:pattern })->len() ==# 0
    let dir = dir->fnamemodify(':h')
  endwhile
  return dir
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
  const start = searchpos(pattern, 'b')
  const end = searchpos('^endfunction', 'n')
  const word = a:word->matchstr('a:\zs\w\+')
  const inFuncDefStatement = printf('\%%%dl\<%s\>', start[0], word)
  const inFuncBodyStatement = printf(
        \ '\%%>%dl\%%<%dl\<a:%s\>',
        \ start[0],
        \ end[0],
        \ word)
  let @/ = printf(
        \ '\V\%(%s\|%s\)',
        \ inFuncDefStatement,
        \ inFuncBodyStatement
        \)
endfunction

" vim:cc=78 tw=78 fo+=t
