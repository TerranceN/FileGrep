let g:file_grep_plugin_dir = expand("<sfile>:p:h:h")

if v:version < 704
  echom "FileGrep: Vim < 7.4 not supported"
endif

if !exists('g:file_grep_tab_move')
  let g:file_grep_tab_move = 0
endif

let g:file_grep_tab_fcn = "new"
if has("gui")
  let g:file_grep_tab_fcn = "drop"
endif

augroup file_grep_keys
  au!
  au FileType file_grep call File_grep_key_mappings()
augroup END
function! File_grep_key_mappings()
  nnoremap <buffer> <leader><CR> :call FileGrepOverwrite()<CR>
  inoremap <buffer> <CR> <ESC>j:call FileGrepOpenNewTab()<CR>
  nnoremap <buffer> <CR> :call FileGrepOpenNewTab()<CR>
  inoremap <buffer> <C-v> <ESC>:call FileGrepOpenInSplit()<CR>
  nnoremap <buffer> <C-v> :call FileGrepOpenInSplit()<CR>
  inoremap <buffer> <C-a> <ESC>:q<CR>
  nnoremap <buffer> <C-a> :q<CR>
  augroup file_grep_on_change
    au!
    au TextChangedI <buffer> call FileGrepInputChanged()
    au TextChanged <buffer> call FileGrepInputChanged()
    au BufWinLeave <buffer> bd
  augroup END
endfunction
function! FileGrepInputChanged()
  let g:file_grep_last_command=getline(1)
  silent! call FileGrep()
endfunction
function! OpenFileGrepSearch()
  silent! call FileGrepBuffer()
  startinsert
endfunction
function! FileGrepBuffer()
  10new
  set buftype=nofile
  set filetype=file_grep
  file FileGrep
endfunction
function! FileGrep()
  let a:cursor_pos = getpos(".")
  let $INPUT=getline(1)
  if $INPUT==""
    let $INPUT=g:file_grep_last_command
    call append(0, $INPUT)
  endif
  :2
  silent! :2,$d
  exec "silent 1read !" . g:file_grep_plugin_dir . "/git_grep_files \"" . escape($INPUT, "") . "\""
  syntax clear
  syn match File "^[^:]*:"
  hi File ctermfg=yellow
  let i = 0
  let words = split($INPUT)
  let colors = ["red", "27", "green", "gray"]
  while i < len(words)
    execute "syn match Match" . i . " \"" . words[i] . "\\V\\c\""
    execute "hi Match" . i . " ctermfg=" . colors[i%len(colors)]
    let i += 1
  endwhile
  normal! gg
  call cursor(a:cursor_pos[1], a:cursor_pos[2])
endfunction
function! FileGrepOpenInSplit()
  if line(".")==1
    let $RAW_INPUT=getline(2)
  else
    let $RAW_INPUT=getline(".")
  endif
  let $INPUT=substitute($RAW_INPUT, ":.*", "", "")
  let $LINE_NUMBER=substitute($RAW_INPUT, "^[^:]*:\\([^:]*\\):.*$", "\\1", "")
  :q
  exec "vsp " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
  exec ":" . $LINE_NUMBER
endfunction
function! FileGrepOpenNewTab()
  if line(".")==1
    let $RAW_INPUT=getline(2)
    if $RAW_INPUT==""
      call FileGrep()
      return
    endif
  else
    let $RAW_INPUT=getline(".")
  endif
  let $INPUT=substitute($RAW_INPUT, ":.*", "", "")
  let $LINE_NUMBER=substitute($RAW_INPUT, "^[^:]*:\\([^:]*\\):.*$", "\\1", "")
  :q
  if g:file_grep_tab_move
    tabm +99999
  endif
  exec "tab " . g:file_grep_tab_fcn . " " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
  exec ":" . $LINE_NUMBER
  if g:file_grep_tab_move
    tabm +99999
  endif
endfunction
function! FileGrepOverwrite()
  if line(".")!=1
    let $RAW_INPUT=getline(".")
    let $INPUT=substitute($RAW_INPUT, ":.*", "", "")
    let $LINE_NUMBER=substitute($RAW_INPUT, "^[^:]*:\\([^:]*\\):.*$", "\\1", "")
    :q
    exec ":e " . substitute(system("git rev-parse --show-toplevel"), "\n "", "") . "/" . $INPUT
    exec ":" . $LINE_NUMBER
  endif
endfunction
