" =============================================================================
" qtmplsel.vim - Quick Template Selector Plugin
"=============================================================================
"
" Author:  Takahiro SUZUKI <takahiro.suzuki.ja@gmDELETEMEail.com>
" Version: 1.1.1 (Vim 7.1)
" URL:     http://www.vim.org/scripts/script.php?script_id=2761
" Licence: GNU General Public License
"=============================================================================
" Document: {{{1
"
"-----------------------------------------------------------------------------
" Description:
"   This plugin enables you to select a template on creating a new file.
"   Templates are typically placed in ~/.vim/template .
"   On creating a file, corresponding templates, if any, are listed up. You
"   can select one of them by k(up)/j(down). Press Enter to load the selected
"   template, or press 'q' to load no templates.
"   You can cancel the insertion of selected template by pressing 'u'(undo).
"
"   There is an optional global varialbe:
"     g:qts_templatedir : specifies the template dir
"                         (default: ~/.vim/template)
"
"   Template search rules:
"     1) by filetype
"       filetype=python -> ~/.vim/template/python_*
"     2) by suffix
"       *.cpp           -> ~/.vim/template/*.cpp
"     3) by filename
"       Makefile        -> ~/.vim/template/Makefile_*
"
"   Note that especially in case 3, 'Makefile_' is a legal template name
"   but 'Makefile' is not even if you have no other template file.
"
"   New in 1.1.0 - expression expansion:
"     String surrounded by '@{@' '@}@' in the template file is regarded as a vim
"     expression, and will be eval()ed on loading.
"     e.g.)
"       @{@expand('%:t')@}@          ->  newfile.py
"       @{@strftime('%Y-%m-%d')@}@   ->  2009-08-30
"
"-----------------------------------------------------------------------------
" Installation:
"   Place this file in /usr/share/vim/vim*/plugin or ~/.vim/plugin/
"
"-----------------------------------------------------------------------------
" ChangeLog:
"   1.1.1:
"     - up and down arrow keys as well as j/k (thanks to Steve Michalske)
"     - quit on <Esc>
"
"   1.1.0:
"     - expression expansion (@{@vim-expression@}@)
"
"   1.0.0:
"     - Initial release
"
" }}}
"=============================================================================
if v:version < 700 | finish | endif

let s:cpo = &cpo
set cpo&vim

if !exists("g:qts_templatedir") || g:qts_templatedir==""
  for s:path in ["$HOME/.vim/template", "$VIMRUNTIME/template"]
    let s:path = expand(s:path)
    if isdirectory(s:path) | let g:qts_templatedir = s:path | break | endif
  endfor
  if !exists('g:qts_templatedir') | finish | endif
  unlet s:path
endif

if exists("s:qts_loaded") && s:qts_loaded | finish | endif
let s:qts_loaded = 1
let s:qts_initialized = 0

augroup QuickTemplateSelector
  autocmd!
  autocmd BufNewFile * call s:Initialize() | call s:LoadTemplate()
augroup END

function! s:Initialize()
  if s:qts_initialized == 1 | return | endif
  let s:qts_initialized = 1
  let s:save_cmdheight = &cmdheight
  cnoremap j      <C-U>j<CR>:call <SID>ShowList()<CR>
  cnoremap k      <C-U>k<CR>:call <SID>ShowList()<CR>
  cnoremap <Down> <C-U>j<CR>:call <SID>ShowList()<CR>
  cnoremap <Up>   <C-U>k<CR>:call <SID>ShowList()<CR>
  cnoremap q      <C-U>q<CR>
  cnoremap <C-C>  <C-U>q<CR>
  cnoremap <Esc>  <C-U>q<CR>
endfunction

function! s:Finalize()
  if s:qts_initialized == 0 | return | endif
  let s:qts_initialized = 0
  let &cmdheight = s:save_cmdheight
  cunmap j
  cunmap k
  cunmap <Down>
  cunmap <Up>
  cunmap q
  cunmap <C-C>
  cunmap <Esc>
  set nomodified
  redraw!
endfunction

function! s:GlobTemplates(pat)
  return split(glob(g:qts_templatedir.'/'.a:pat), '\n')
endfunction

function! s:LoadTemplate()
  " enumerate
  let s:templatelist = []
    \+ s:GlobTemplates(&ft.'_*')
    \+ s:GlobTemplates('*.'.expand('%:e'))
    \+ s:GlobTemplates(expand('%:t:r').'_*')
  " unique
  let l:tmpkeys = {}
  for l:fname in s:templatelist | let l:tmpkeys[l:fname] = '' | endfor
  let s:templatelist = sort(keys(l:tmpkeys))

  let s:llen = len(s:templatelist)
  if s:llen == 0
    call s:Finalize()
  else
    let s:sel = 0
    call s:ShowList()
  endif
endfunction

function! s:ShowList()
  exe 'set cmdheight='.(s:llen+1)
  redraw!
  for l:i in range(s:llen)
    let l:filename = fnamemodify(s:templatelist[l:i], ':t')
    if s:sel == l:i
      echohl DiffText | echo '> '.l:filename | echohl None
    else
      echo '  '.l:filename
    endif
  endfor

  let l:key = input('select template (j/k, Enter(select), q(uit)):', '')
  if l:key == 'j'
    let s:sel = (s:sel+1) % s:llen
  elseif l:key == 'k'
    let s:sel = (s:llen+s:sel-1) % s:llen
  elseif l:key == ''
    " load template and eval expression in @{@..@}@
    for line in readfile(s:templatelist[s:sel])
      let line = substitute(line, '@{@\(.\{-1,}\)@}@', '\=eval(submatch(1))', 'g')
      put =line
    endfor
    normal ggdd
    call s:Finalize()
  else
    " quit
    call s:Finalize()
  endif
endfunction

let &cpo=s:cpo
unlet s:cpo

" vim: set et sts=2 sw=2 ts=2 fdm=marker:
