" =============================================================================
" Filename: autoload/qfedit.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/11/21 21:57:20.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! qfedit#new() abort
  if &l:buftype !=# 'quickfix' || !get(g:, 'qfedit_enable', 1)
    return
  endif
  let b:qfedit_items = qfedit#items()
  augroup qfedit
    autocmd TextChanged <buffer> call qfedit#change()
  augroup END
  let b:qfedit_changedtick = b:changedtick
  augroup qfedit-cursormoved
    autocmd CursorMoved <buffer> call qfedit#moved()
  augroup END
  call qfedit#setlocal()
endfunction

function! qfedit#items() abort
  let items = {}
  for item in qfedit#is_loclist() ? getloclist(0) : getqflist()
    let key = qfedit#line(item)
    if key !=# ''
      let items[key] = item
    endif
  endfor
  return items
endfunction

function! qfedit#line(item) abort
  return  (a:item.bufnr ? bufname(a:item.bufnr) : '') . '|' .
        \ (a:item.lnum  ? a:item.lnum           : '') .
        \ (a:item.col   ? ' col ' . a:item.col  : '') .
        \ qfedit#type(a:item.type, a:item.nr) . '|' .
        \ substitute(a:item.text, '^[[:blank:]]*', ' ', '')
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

function! qfedit#moved() abort
  if !has_key(b:, 'qfedit_changedtick')
    augroup qfedit-cursormoved
      autocmd! * <buffer>
    augroup END
    return
  endif
  if b:changedtick != b:qfedit_changedtick
    unlet! b:qfedit_changedtick
    call qfedit#change()
    augroup qfedit-cursormoved
      autocmd! * <buffer>
    augroup END
  endif
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
  if !has_key(b:, 'qfedit_items')
    let b:qfedit_items = {}
  endif
  let list = []
  for line in getline(1, '$')
    if has_key(b:qfedit_items, line)
      call add(list, b:qfedit_items[line])
    endif
  endfor
  if qfedit#is_loclist()
    call setloclist(0, list, 'r')
  else
    let prev_title = getqflist({'title': 0})
    call setqflist(list, 'r')
    call setqflist([], 'r', prev_title)
  endif
endfunction

function! qfedit#is_loclist() abort
  return get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
endfunction

function! qfedit#setlocal() abort
  setlocal modifiable nomodified noswapfile
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
