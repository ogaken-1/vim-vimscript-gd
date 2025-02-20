function! vimscript_gd#jump() abort
  let isk = &iskeyword
  setl isk+=:
  const word = expand('<cword>')
  let &iskeyword = isk

  if word =~# '^\%(\w\+#\)\+'
    call s:SearchAutoloadSymbol(word)
  elseif word =~# 's:\w\+'
    call s:SearchScriptLocalSymbol(word)
  elseif word =~# 'a:\w\+'
    call s:SearchFunctionArgumentSymbol(word)
  else
    call search(s:defcmd..'\s\+\zs'..word, 'bc')
    let @/ = word->printf('\V\<%s\>')
  endif
endfunction

const s:funcDefPattern = '\<fu\%[nction]\>!\?'
const s:defcmd = '\%('..s:funcDefPattern..'\|\<let\>\|\<const\>\)'

function! s:Sub(text, from, to) abort
  return a:text->substitute(a:from, a:to, 'g')
endfunction

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
    const file = files[0]
    if !file->bufexists()
      call bufadd(file)
    endif
    exe 'buffer' file->bufnr()
    call search(a:word->printf('\V'..s:Sub(s:defcmd, '%', '%%')..'\s\zs\<%s\>'))
    let @/ = a:word->printf('\V\<%s\>')
  endif
endfunction

function! s:FindRoot(path, pattern) abort
  let dir = a:path->isdirectory() ? a:path : a:path->fnamemodify(':p:h')
  while dir !=# '/'
        \ && dir->readdir({ fname -> fname =~# a:pattern })->len() ==# 0
    let dir = dir->fnamemodify(':h')
  endwhile
  return dir
endfunction

function! s:SearchScriptLocalSymbol(word) abort
  call cursor(1, 1)
  const word = a:word->matchstr('s:\zs\w\+')
  call search(word->printf('\V'..s:Sub(s:defcmd, '%', '%%')..'\s\<s:\zs%s\>'))
  let @/ = word->printf('\V\<s:\zs%s\>')
endfunction

function! s:SearchFunctionArgumentSymbol(word) abort
  if a:word =~# 'a:\%(\d\|000\)'
    const pattern = '\V'..s:funcDefPattern..'\.\+\zs...'
    const word = '\%(\d\|000\)'
    const start = searchpos(pattern, 'b')
    const inFuncDefStatement = printf('\%%%dl...', start[0])
  else
    const start = a:word
          \ ->matchstr('a:\zs\w\+')
          \ ->printf('\V'..s:Sub(s:funcDefPattern, '%', '%%')..'\.\+\zs%s')
          \ ->searchpos('b')
    const word = a:word->matchstr('a:\zs\w\+')
    const inFuncDefStatement = printf('\%%%dl\<%s\>', start[0], word)
  endif
  const end = searchpos('^\s*endfu\%[nction]', 'n')
  const inFuncBodyStatement = printf(
        \ '\%%>%dl\%%<%dl\<a:\zs%s\>',
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
