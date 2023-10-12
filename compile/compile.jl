import Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

import Git
import PackageCompiler

const git = Git.git()
const COMPILE_DIR = @__DIR__
const CompareScenariosGenerators_DIR = dirname(COMPILE_DIR)
const BUILD_DIR = joinpath(COMPILE_DIR, "builddir")

@info("COMPILE-CompareScenariosGenerators: Creating build dir")
if isdir(BUILD_DIR)
    rm(BUILD_DIR; force = true, recursive = true)
end
mkdir(BUILD_DIR)

@info "COMPILE-CompareScenariosGenerators: Set version hash"
CURRENT = pwd()
cd(CompareScenariosGenerators_DIR)
try
    ver = readchomp(`$git rev-parse --short HEAD`)
    open(joinpath(CompareScenariosGenerators_DIR, "src", "version.jl"), "w") do io
        write(io, "const _VERSION = \"$(ver)\"")
    end
catch
    @warn "Could not run git rev-parse --short HEAD"
end
cd(CURRENT)

@info "COMPILE-CompareScenariosGenerators: Starting PackageCompiler create_app function"
PackageCompiler.create_app(
    CompareScenariosGenerators_DIR,
    joinpath(BUILD_DIR, "CompareScenariosGenerators");
    executables = [
        "run_evaluation_loop" => "jl_evaluation_loop", 
        "report_metrics" => "jl_report_metrics",
        ],
    filter_stdlibs = true,
    incremental = false,
    include_lazy_artifacts = true,
    precompile_execution_file = joinpath(COMPILE_DIR, "compilation_script.jl"),
    force = true,
    include_transitive_dependencies = false
)

@info "COMPILE-CompareScenariosGenerators: Cleaning version file"
open(joinpath(CompareScenariosGenerators_DIR, "src", "version.jl"), "w") do io
    write(io, "const _VERSION = \"\"")
end

@info "COMPILE-CompareScenariosGenerators: Build Success"
