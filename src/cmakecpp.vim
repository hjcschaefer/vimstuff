
function! Relpath(filename)
    let cwd = fnamemodify(getcwd(), ':h')
    let s =  './' .  substitute(a:filename, l:cwd . "/" , "", "")
    return s
endfunction

function! FindNearestCmakeFile()
    let l:path = expand('%:p:h') " path without current file
    let l:n = 0
    while !filereadable(l:path . "/CMakeLists.txt") && l:n < 5
        let l:path = fnamemodify(l:path, ':h')
        let l:n += 1
    endwhile
    if !(l:n < 5)
        throw "Not in CMake Build Tree?"
    endif
    return (l:path)
endfunction()

function! GetTestExecutable()
    " find closest CMakeLists.txt
    let l:path = FindNearestCmakeFile()
    " try to get test name
    let l:gtest = system('grep -i add_gtest ' . l:path . '/CMakeLists.txt')
    if (len(l:gtest) > 0)
        let l:tt = matchlist(l:gtest, '\w\+(\(\w\+\)\s')
        let l:testname = l:tt[1]
        let l:path_to_exe = Relpath(l:path)
        let l:executable = l:path_to_exe . '/' . l:testname . '-test'
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


