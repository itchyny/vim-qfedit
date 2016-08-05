" =============================================================================
" Filename: autoload/qfedit.vim
" Author: itchyny
" License: MIT License
" Last Change: 2016/08/05 22:16:33.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! qfedit#new() abort
  if &l:buftype !=# 'quickfix' || !get(g:, 'qfedit_enable', 1)
    return
  endif
  augroup qfedit
    autocmd TextChanged <buffer> call qfedit#change()
  augroup END
  augroup qfedit-qfdict
    autocmd CursorMoved <buffer> let s:qfitems = qfedit#qfdict() |
          \ augroup qfedit-qfdict | autocmd! | augroup END
  augroup END
  call qfedit#setlocal()
endfunction

function! qfedit#qfdict() abort
  let qfitems = {}
  for item in qfedit#locationlist() ? getloclist(0) : getqflist()
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
  if qfedit#locationlist()
    call setloclist(0, list, 'r')
  else
    call setqflist(list, 'r')
  endif
endfunction

function! qfedit#locationlist() abort
  return get(b:, 'qflisttype', '') ==# 'location'
endfunction

function! qfedit#setlocal() abort
  setlocal modifiable nomodified noswapfile
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
