module CompareScenariosGenerators

using ArgParse
using CSV
using DataFrames
using JSON
using OrderedCollections
using PlotlyJS
using TOML

# Std libs usadas
using Dates
using LinearAlgebra
using Mmap
using Random
using SHA
using Statistics
using StatsBase

include("version.jl")

function version()
    return _VERSION
end

include("utils.jl")
include("model_evaluation.jl")
include("plot_recipes.jl")
include("evaluation_metrics.jl")
include("report_metrics.jl")
include("main.jl")
include("metrics_tables.jl")

end # module
