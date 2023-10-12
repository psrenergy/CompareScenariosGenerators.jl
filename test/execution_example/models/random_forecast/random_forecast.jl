import Pkg
Pkg.activate(@__DIR__())
Pkg.instantiate()

using CSV
using DataFrames
using Dates
using Random
Random.seed!(1)

time_series_path = ARGS[1]
num_steps_ahead = parse(Int, ARGS[2])
num_scenarios = parse(Int, ARGS[3])


ts = CSV.File(time_series_path) |> DataFrame
ts_names = names(ts)[2:end]
ts_dates = ts.dates
observations = Matrix{Float64}(ts[1:end, 2:end])
last_date = ts_dates[end]

simulation_result = Array{Float64}(undef, num_steps_ahead, length(ts_names), num_scenarios)
for i in 1:length(ts_names)
    # model simulation
    simulation_result[:, i, :] = randn(num_steps_ahead, num_scenarios) * 100 .+ observations[end, i]
end

# Write results
simulation_df = DataFrame(
    "dates" => Vector{Date}(undef, 0), 
    "scenario" => Vector{Int}(undef, 0), 
    [name => Vector{Float64}(undef, 0) for name in ts_names]...
)

for s in 1:num_scenarios, t in 1:num_steps_ahead
    push!(simulation_df, 
        vcat(
            last_date + Month(t),
            s,
            simulation_result[t, :, s]
        )
    )
end

output_path = joinpath(dirname(time_series_path), "_simulated_scenarios.csv")
CSV.write(output_path, simulation_df)
