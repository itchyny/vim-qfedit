" =============================================================================
" Filename: autoload/qfedit.vim
" Author: itchyny
" License: MIT License
" Last Change: 2015/01/22 23:54:00.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! qfedit#new() abort
  if &l:buftype !=# 'quickfix' || !get(g:, 'qfedit_enable', 1)
    return
  endif
  let s:qfitems = qfedit#qfdict()
  augroup qfedit
    autocmd TextChanged <buffer> call qfedit#change()
  augroup END
  call qfedit#setlocal()
endfunction

function! qfedit#qfdict() abort
  let qfitems = {}
  for item in getqflist()
    let key = qfedit#line(item)
    if key !=# ''
      let qfitems[key] = item
    endif
  endfor
  return qfitems
endfunction

function! qfedit#line(item) abort
  return  (a:item.bufnr ? bufname(a:item.bufnr) : '') . '|' .
        \ (a:item.lnum  ? a:item.lnum           : '') .
        \ (a:item.col   ? ' col ' . a:item.col  : '') .
        \ qfedit#type(a:item.type, a:item.nr) . '|' .
        \ substitute(a:item.text, '^ *', ' ', '')
endfunction

function! qfedit#type(type, nr) abort
  if a:type ==? 'W'
    let msg = ' warning'
  elseif a:type ==? 'I'
    let msg = ' info'
  elseif a:type ==? 'E'
    let msg = ' error'
  elseif a:type ==# "\0" || a:type ==# "\1"
    let msg = ''
  else
    let msg = ' ' . a:type
  endif
  if a:nr <= 0
    return msg
  endif
  return msg . ' ' . printf('%3d', a:nr)
endfunction

function! qfedit#change() abort
  let position = getpos('.')
  let view = winsaveview()
  call qfedit#restore()
  call winrestview(view)
  call setpos('.', position)
  call qfedit#setlocal()
endfunction

function! qfedit#restore() abort
  if !has_key(s:, 'qfitems')
    let s:qfitems = {}
  endif
  let list = []
  for line in getline(1, '$')
    if has_key(s:qfitems, line)
      call add(list, s:qfitems[line])
    endif
  endfor
  call setqflist(list, 'r')
endfunction

function! qfedit#setlocal() abort
  setlocal modifiable nomodified noswapfile
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
