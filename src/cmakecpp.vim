
function! Gitblame()
    " Get current file
    let l:fname = expand('%')
    let l:lineno = line('.')
    let l:lastline = line('$')
    let l:linestart = max([l:lineno-5, 1])
    let l:lineend = min([l:lineno+5, l:lastline])
    let l:blame = system('git blame -L ' . l:linestart . ',' . l:lineend . ' ' . l:fname)
    return l:blame
endfunction

function! Gitblame2()
    let l:fname = expand('%')
    let l:lineno = line('.')
    let l:blame = system('git blame -L ' . l:lineno . ',' . l:lineno . ' ' . l:fname)
    let l:sha = split(l:blame, ' ')[0]
    return system('git show ' . l:sha)
endfunction


function! Relpath(filename)
    " Bad hack to get /export in and work on linux
    let l:cwd = fnamemodify(getcwd(), ':h:s?export??')
    let s =  './' .  substitute(a:filename, l:cwd . "/" , "", "")
    return s
endfunction

function! FindNearestCmakeFile()
    let l:path = expand('%:p:h:s?export??') " path without current file
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
        let l:tt = matchlist(l:gtest,  '\w\+(\(\S\+\)\s\+')
        " let l:tt = matchlist(l:gtest,  '\w\+(\(.\+\)\s\+')
        let l:testname = l:tt[1]
        let l:path_to_exe = Relpath(l:path)
        let l:executable = l:path_to_exe . '/' . l:testname . '-test'
        return(l:executable)
    endif
endfunction()

function! ParseTestDefinition()
    let l:line = getline('.')
    let l:parts = matchlist(l:line, 'TEST_F(\(.\+\),\s\+\(.\+\))') " (\(\w+\))')
    return " --gtest_filter=" . l:parts[1]  . "." . l:parts[2]
endfunction()

function! ParseTestDefinition2()
    let l:line = getline('.')
    let l:parts = matchlist(l:line, 'TEST_F(\(.\+\),\s\+\(.\+\))') " (\(\w+\))')
    return l:parts[1]
endfunction()

function! RunTest()
    let l:exe = GetTestExecutable()
    let l:cmd = expand('<cword>')
    let l:testname = expand('%:t:r')
    let l:target = split(l:exe, '/')[-1]
    let l:filter = ParseTestDefinition()
    let l:testclass = ParseTestDefinition2()
    execute "command! RR :!" . l:exe . l:filter
    execute "command! MM :make " . l:target
    call WriteGDBInit(l:exe, l:filter, expand('%:t'), line('.')+1)
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

function! WriteGDBInit(exename, filter, srcname, lineno)
    new .gdbinit
    1,$delete
    call append('$', 'file ' . a:exename)
    call append('$', 'catch throw')
    call append('$', 'b ' . a:srcname . ':' . a:lineno)
    call append('$', 'r ' . a:filter)
    write
    quit
endfunction()


