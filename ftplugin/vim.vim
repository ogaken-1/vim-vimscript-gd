if !get(g:, 'gd_disable_default_mapping', v:false)
  nnoremap <buffer> gd <Plug>(vimscript-gd)
endif
nnoremap <buffer> <Plug>(vimscript-gd) m'<Cmd>keepjumps call gd#jump()<CR>
