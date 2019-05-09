" =============================================================================
" Filename: autoload/qfedit.vim
" Author: itchyny
" License: MIT License
" Last Change: 2019/05/09 15:23:23.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! qfedit#new() abort
  if &l:buftype !=# 'quickfix' || !get(g:, 'qfedit_enable', 1)
    return
  endif
  let b:qfedit_items = qfedit#items(qfedit#list())
  augroup qfedit-textchanged
    autocmd! * <buffer>
    autocmd TextChanged <buffer> call qfedit#change()
  augroup END
  let b:qfedit_changedtick = b:changedtick
  augroup qfedit-cursormoved
    autocmd! * <buffer>
    autocmd CursorMoved <buffer> call qfedit#moved()
  augroup END
  let b:qfedit_lastline = [line('$'), getline('$')]
  call qfedit#setlocal()
endfunction

function! qfedit#list() abort
  return qfedit#is_loclist() ? getloclist(0) : getqflist()
endfunction

function! qfedit#items(list) abort
  let items = {}
  for item in a:list
    let items[qfedit#line(item)] = item
  endfor
  return items
endfunction

function! qfedit#line(item) abort
  let fname = bufname(a:item.bufnr)
  if a:item.type ==# "\1"
    let fname = fnamemodify(fname, ':t')
  endif
  return  (a:item.bufnr ? fname : '') . '|' .
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
  if b:qfedit_lastline[0] < line('$')
        \ && b:qfedit_lastline[1] ==# getline(b:qfedit_lastline[0])
    call extend(b:qfedit_items,
          \ qfedit#items(qfedit#list()[b:qfedit_lastline[0]:]))
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
  let b:qfedit_lastline = [line('$'), getline('$')]
endfunction

function! qfedit#is_loclist() abort
  return get(get(getwininfo(win_getid()), 0, {}), 'loclist', 0)
endfunction

function! qfedit#setlocal() abort
  setlocal modifiable nomodified noswapfile
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
