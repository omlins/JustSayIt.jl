push!(LOAD_PATH, "../src")

excludedfiles = [ "test_excluded.jl"];

function runtests()
    exename      = joinpath(Sys.BINDIR, Base.julia_exename())
    testdir      = pwd()
    istest(f)    = endswith(f, ".jl") && startswith(basename(f), "test_")
    ispretest(f) = endswith(f, ".jl") && startswith(basename(f), "pretest_")    # NOTE: pretest_JustSayIt1.jl, pretest_JustSayIt2.jl test the Python related installations (restart needed after first installation!).
    testfiles    = sort(filter(istest,    vcat([joinpath.(root, files) for (root, dirs, files) in walkdir(testdir)]...)))
    pretestfiles = sort(filter(ispretest, vcat([joinpath.(root, files) for (root, dirs, files) in walkdir(testdir)]...)))

    nfail = 0
    printstyled("Testing package JustSayIt.jl\n"; bold=true, color=:white)
    for f in [pretestfiles; testfiles]
        println("")
        if f ∈ excludedfiles
            println("Test Skip:")
            println("$f")
            continue
        end
        try
            run(`$exename -O3 --startup-file=no $(joinpath(testdir, f))`)
        catch ex
            nfail += 1
        end
    end
    return nfail
end
exit(runtests())
