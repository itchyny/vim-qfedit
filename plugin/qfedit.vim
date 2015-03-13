" =============================================================================
" Filename: plugin/qfedit.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/03/10 17:05:03.
" =============================================================================

if exists('g:loaded_qfedit') || v:version < 700 || !exists('##TextChanged')
  finish
endif
let g:loaded_qfedit = 1

let s:save_cpo = &cpo
set cpo&vim

augroup qfedit
  autocmd!
  autocmd BufReadPost quickfix call qfedit#new()
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
