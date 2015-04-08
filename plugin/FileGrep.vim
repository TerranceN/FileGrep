let g:file_grep_plugin_dir = expand("<sfile>:p:h:h")

augroup file_grep_keys
    au!
    au FileType file_grep call File_grep_key_mappings()
augroup END
function! File_grep_key_mappings()
    nnoremap <buffer> <leader><CR> :call FileGrepOverwrite()<CR>
    inoremap <buffer> <CR> <ESC>j:call FileGrepOpenNewTab()<CR>
    nnoremap <buffer> <CR> :call FileGrepOpenNewTab()<CR>
    nnoremap <buffer> T :call FileGrepOpenInNewTab()<CR>
    augroup file_grep_on_change
        au!
        au TextChangedI <buffer> call FileGrep()
    augroup END
endfunction
function! OpenFileGrepSearch()
    10new
    set buftype=nofile
    set filetype=file_grep
    file FileGrep
    startinsert
endfunction
function! FileGrep()
    let a:cursor_pos = getpos(".")
    let $INPUT=getline(1)
    :2
    silent normal! 9999dd
    exec "silent 1read !" . g:file_grep_plugin_dir . "/git_grep_files " . $INPUT
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
function! FileGrepOpenNewTab()
    if line(".")==1
        call FileGrep()
    else
        let $RAW_INPUT=getline(".")
        let $INPUT=substitute($RAW_INPUT, ":.*", "", "")
        let $LINE_NUMBER=substitute($RAW_INPUT, "^[^:]*:\\([^:]*\\):.*$", "\\1", "")
        :q
        exec "tab drop " . substitute(system("git rev-parse --show-toplevel"), "\n", "", "") . "/" . $INPUT
        exec ":" . $LINE_NUMBER
    endif
endfunction
function! FileGrepOpenInNewTab()
    if line(".")!=1
        let $RAW_INPUT=getline(".")
        let $INPUT=substitute($RAW_INPUT, ":.*", "", "")
        let $LINE_NUMBER=substitute($RAW_INPUT, "^[^:]*:\\([^:]*\\):.*$", "\\1", "")
        tabnew $INPUT
        exec "tabnew " . substitute(system("git rev-parse --show-toplevel"), "\n "", "") . "/" . $INPUT
        exec ":" . $LINE_NUMBER
        tabprevious
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
