
function! Relpath(filename)
    let cwd = fnamemodify(getcwd(), ':h')
    let s =  './' .  substitute(a:filename, l:cwd . "/" , "", "")
    return s
endfunction

function! GetTestExecutable()
    " find closest CMakeLists.txt
    let l:path = expand('%:p:h') " path without current file
    " check if we have a CMakeLists.txt here
    if !filereadable(l:path . "/CMakeLists.txt")
        let l:path = fnamemodify(l:path, ':h')
        if !filereadable(l:path . "/CMakeLists.txt")
            return
        endif
    endif
    " try to get test name
    let l:gtest = system('grep -i add_gtest ' . l:path . '/CMakeLists.txt')
    if (len(l:gtest) > 0)
        let l:tt = matchlist(l:gtest, '\w\+(\(.\+\)\s')
        let l:testname = l:tt[1]
        let l:pathx = Relpath(expand('%:p:h')) " relative path without current file
        let l:executable = l:pathx . '/' . l:testname . '-test'
        return(l:executable)
    endif
endfunction()

function! RunTest()
    let l:exe = GetTestExecutable()
    let l:cmd = expand('<cword>')
    let l:testname = expand('%:t:r')
    let l:target = split(l:exe, '/')[-1]
    execute "command! RR :!" . l:exe . " --gtest_filter=" . l:testname . "." . l:cmd
    execute "command! MM :make " . l:target
endfunction()

function! RunAllTestsInFile()
    let l:exe = GetTestExecutable()
    let l:testname = expand('%:t:r')
    let l:target = split(l:exe, '/')[-1]
    execute ":!make " . l:target . "&&" . l:exe . ' --gtest_filter=' . l:testname . '.*'
endfunction()

function! RunAllTestsInSuite()
    let l:exe = GetTestExecutable()
    let l:testname = expand('%:t:r')
    let l:target = split(l:exe, '/')[-1]
    execute ":!make " . l:target . "&&" . l:exe
endfunction()

function! AddNewTest()
    let l:testname = expand('%:t:r')
    return 'TEST_F('.l:testname.', ) {'
endfunction()


