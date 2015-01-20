" =============================================================================
" Filename: plugin/qfedit.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/01/15 13:50:25.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

if exists('g:loaded_qfedit') || v:version < 700 || !exists('##TextChanged')
  finish
endif
let g:loaded_qfedit = 1

augroup qfedit
  autocmd!
  autocmd BufReadPost quickfix call qfedit#new()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
