let s:file_grep_plugin_dir = expand("<sfile>:p:h:h")

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

func! PreFileGrep()
  let a:cursor_pos = getpos(".")
  :2
  silent! :2,$d
  return a:cursor_pos
endfunc

func! PostFileGrep(cursor_pos)
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
endfunc

if v:version >= 800
  func! FileGrepJobMessageHandler(channel, msg)
    if exists("b:fileGrepJob")
      let b:fileGrepResults = b:fileGrepResults + [a:msg]
    endif
  endfunc

  func! FileGrepJobFinishedHandler(channel)
    if exists("b:fileGrepJob")
      unlet b:fileGrepJob
      if len(b:fileGrepResults) > 0
        let a:cursor_pos = PreFileGrep()
        1pu =b:fileGrepResults
        call PostFileGrep(a:cursor_pos)
        if exists("b:fileGrepOnFinishFunction")
          let $INPUT=getline(2)
          exec "call " . b:fileGrepOnFinishFunction . "($INPUT)"
        endif
      endif
    endif
  endfunc

  func! FileGrepStartJob(input)
    if exists("b:fileGrepJob")
      let b:fileGrepResults = []
      let channel = job_getchannel(b:fileGrepJob)
      call ch_close(channel)
      call job_stop(b:fileGrepJob, "kill")
    endif
    let b:fileGrepResults = []
    let b:fileGrepJob = job_start(["/bin/bash", "-c", ("" . s:file_grep_plugin_dir . "/git_grep_files \"" . escape(a:input, "") . "\"")], {"out_cb": "FileGrepJobMessageHandler", "close_cb": "FileGrepJobFinishedHandler"})
  endfunc
end

augroup file_grep_keys
  au!
  au FileType file_grep call File_grep_key_mappings()
augroup END
function! File_grep_key_mappings()
  nnoremap <buffer> <leader><CR> :call FileGrepOverwrite()<CR>
  inoremap <buffer> <CR> <ESC>:call FileGrepOpenNewTab()<CR>
  nnoremap <buffer> <CR> :call FileGrepOpenNewTab()<CR>
  inoremap <buffer> <C-v> <ESC>:call FileGrepOpenInSplit()<CR>
  nnoremap <buffer> <C-v> :call FileGrepOpenInSplit()<CR>
  inoremap <buffer> <C-a> <ESC>:q<CR>
  nnoremap <buffer> <C-a> :q<CR>
  augroup file_grep_on_change
    au!
    au TextChangedI <buffer> call FileGrepInputChanged()
    "au TextChanged <buffer> call FileGrepInputChanged()
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
  normal! gg
  call cursor(a:cursor_pos[1], a:cursor_pos[2])
  if v:version >= 800
    call FileGrepStartJob($INPUT)
  else
    let a:cursor_pos = PreFileGrep()
    exec "silent 1read !" . s:file_grep_plugin_dir . "/git_grep_files \"" . escape($INPUT, "") . "\""
    call PostFileGrep(a:cursor_pos)
  endif
endfunction
function! FileGrepOpenInSplitForInput(input)
  let $INPUT=substitute(a:input, ":.*", "", "")
  let $LINE_NUMBER=substitute(a:input, "^[^:]*:\\([^:]*\\):.*$", "\\1", "")
  :q
  exec "vsp " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
  exec ":" . $LINE_NUMBER
endfunction
function! FileGrepOpenInSplit()
  if line(".")==1
    let $RAW_INPUT=getline(2)
  else
    let $RAW_INPUT=getline(".")
  endif
  if exists("b:fileGrepJob")
    let b:fileGrepOnFinishFunction = 'FileGrepOpenInSplitForInput'
  else
    call FileGrepOpenInSplitForInput($RAW_INPUT)
  endif
endfunction
func! FileGrepOpenNewTabForInput(input)
  let $INPUT=substitute(a:input, ":.*", "", "")
  let $LINE_NUMBER=substitute(a:input, "^[^:]*:\\([^:]*\\):.*$", "\\1", "")
  :q
  if g:file_grep_tab_move
    tabm +99999
  endif
  exec "tab " . g:file_grep_tab_fcn . " " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
  exec ":" . $LINE_NUMBER
  if g:file_grep_tab_move
    tabm +99999
  endif
endfunc
function! FileGrepOpenNewTab()
  if line(".")==1
    if line('$') > 1
      let $RAW_INPUT=getline(2)
      if $RAW_INPUT==""
        let $RAW_INPUT=getline(1)
      endif
    else
      let $RAW_INPUT=getline(1)
      if $RAW_INPUT==""
        let $RAW_INPUT=g:file_grep_last_command
        call append(0, $RAW_INPUT)
        normal! gg
        call FileGrep()
        return
      endif
    endif
  else
    let $RAW_INPUT=getline(".")
  endif
  if exists("b:fileGrepJob")
    let b:fileGrepOnFinishFunction = 'FileGrepOpenNewTabForInput'
  else
    call FileGrepOpenNewTabForInput($RAW_INPUT)
  endif
endfunction
function! FileGrepOverwriteForInput(input)
  let $INPUT=substitute(a:input, ":.*", "", "")
  let $LINE_NUMBER=substitute(a:input, "^[^:]*:\\([^:]*\\):.*$", "\\1", "")
  :q
  exec ":e " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
  exec ":" . $LINE_NUMBER
endfunction
function! FileGrepOverwrite()
  if line(".")==1
    let $RAW_INPUT=getline(2)
  else
    let $RAW_INPUT=getline(".")
  endif
  if exists("b:fileGrepJob")
    let b:fileGrepOnFinishFunction = 'FileGrepOverwriteForInput'
  else
    call FileGrepOverwriteForInput($RAW_INPUT)
  endif
endfunction
