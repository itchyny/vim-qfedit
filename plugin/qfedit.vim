" =============================================================================
" Filename: plugin/qfedit.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/06/25 12:34:11.
" =============================================================================

if exists('g:loaded_qfedit') || !exists('##TextChanged') || !has('patch-7.4.2215')
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
