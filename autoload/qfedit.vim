" =============================================================================
" Filename: autoload/qfedit.vim
" Author: itchyny
" License: MIT License
" Last Change: 2024/10/10 20:02:41.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

function! qfedit#new() abort
  if &l:buftype !=# 'quickfix' || !get(g:, 'qfedit_enable', 1)
    return
  endif
  let b:qfedit_items = qfedit#items(qfedit#getlist())
  let b:qfedit_dir = getcwd()
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

function! qfedit#getlist() abort
  return qfedit#is_loclist() ? getloclist(0) : getqflist()
endfunction

function! qfedit#setlist(list) abort
  if qfedit#is_loclist()
    let title = getloclist(0, {'title': 0})
    call setloclist(0, a:list, 'r')
    call setloclist(0, [], 'r', title)
  else
    let title = getqflist({'title': 0})
    call setqflist(a:list, 'r')
    call setqflist([], 'r', title)
  endif
endfunction

function! qfedit#items(list) abort
  let items = {}
  for item in a:list
    let items[qfedit#line(item)] = item
  endfor
  return items
endfunction

function! qfedit#line(item) abort
  let fname = empty(get(a:item, 'module')) ? bufname(a:item.bufnr) : a:item.module
  if a:item.type ==# "\1"
    let fname = fnamemodify(fname, ':t')
  endif
  let fname = substitute(simplify(fname), '^\V./', '', '')
  return ((a:item.bufnr ? fname : '') . '|' .
        \ (a:item.lnum ? a:item.lnum : '') .
        \ (get(a:item, 'end_lnum') && a:item.lnum != a:item.end_lnum ? '-' . a:item.end_lnum : '') .
        \ (a:item.col ? ' col ' . a:item.col .
        \ (get(a:item, 'end_col') && a:item.col != a:item.end_col ? '-' . a:item.end_col : '')
        \ : '') .
        \ qfedit#type(a:item.type, a:item.nr) . '| ' .
        \ (a:item.valid ? substitute(substitute(a:item.text, '\v^%(\t| )+', '', ''), '\v\n%(\n|\t| )*', ' ', 'g')
        \ : a:item.text)
        \ )[:1023]
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
  if b:qfedit_lastline[0] < line('$')
        \ && b:qfedit_lastline[1] ==# getline(b:qfedit_lastline[0])
    call extend(b:qfedit_items,
          \ qfedit#items(qfedit#getlist()[b:qfedit_lastline[0]:]))
  endif
  let list = []
  for line in getline(1, '$')
    let line = substitute(line, '^[^|]\+', '\=substitute(simplify(submatch(0)), "^\\V./", "", "")', '')[:1023]
    if has_key(b:qfedit_items, line)
      call add(list, b:qfedit_items[line])
    endif
  endfor
  let dir = getcwd()
  try
    lcd `=b:qfedit_dir`
    call qfedit#setlist(list)
  finally
    lcd `=dir`
  endtry
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
