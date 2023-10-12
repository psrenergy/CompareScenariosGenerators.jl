struct ObservationSeries
    names::Vector{String}
    dates::Vector{Date}
    observations::Matrix{Float64}
    function ObservationSeries(
        names::Vector{String},
        dates::Vector{Date},
        observations::Matrix{Float64},
    )
        @assert length(dates) == size(observations, 1)
        @assert length(names) == size(observations, 2)
        return new(names, dates, observations)
    end
end
struct ScenariosSeries
    names::Vector{String}
    dates::Vector{Date}
    scenarios::Array{Float64,3}
    function ScenariosSeries(names::Vector{String}, dates::Vector{Date}, scenarios::Array{Float64,3})
        @assert length(dates) == size(scenarios, 1)
        @assert length(names) == size(scenarios, 2)
        return new(names, dates, scenarios)
    end
end

struct EvaluationInput
    time_series_path::String
    num_steps_ahead::Int
    num_scenarios::Int
    num_windows::Int
    fixed_forecast_window_size::Bool
    model_executable_path::String
    model_name::String
    plot_all_scenarios_windows::Bool
end

function load_evaluation_input(evaluation_config::String)
    evaluation_dict = TOML.parsefile(evaluation_config)
    return EvaluationInput(
        evaluation_dict["time_series_path"],
        evaluation_dict["num_steps_ahead"],
        evaluation_dict["num_scenarios"],
        evaluation_dict["num_windows"],
        evaluation_dict["fixed_forecast_window_size"],
        evaluation_dict["model_executable_path"],
        evaluation_dict["model_name"],
        evaluation_dict["plot_all_scenarios_windows"],
    )
end

function load_time_series(path::String)
    ts = CSV.File(path) |> DataFrame
    ts_names = names(ts)[2:end]
    ts_dates = ts.dates
    observations = Matrix{Float64}(ts[1:end, 2:end])
    return ObservationSeries(ts_names, ts_dates, observations)
end

function load_scenarios(path::String)
    ts = CSV.File(path) |> DataFrame
    ts_names = names(ts)[3:end]
    ts_dates = unique(ts.dates)
    num_obs = length(ts_dates)
    num_scenarios = maximum(ts.scenario)
    grouped_ts = groupby(ts, "scenario")
    scenarios = Array{Float64, 3}(undef, num_obs, length(ts_names), num_scenarios)
    for s in 1:num_scenarios
        scenarios[:, :, s] = Matrix{Float64}(grouped_ts[s][:, 3:end])
    end
    return ScenariosSeries(ts_names, ts_dates, scenarios)
end

function write_time_series(path::String, ts::ObservationSeries)
    table = DataFrame([ts.dates ts.observations], ["dates"; ts.names])
    CSV.write(path, table)
    return path
end

function create_all_input_time_series(
    evaluation_input::EvaluationInput,
    original_time_series::ObservationSeries,
)
    len_original_time_series = size(original_time_series.observations, 1)
    all_input_series = Vector{ObservationSeries}(undef, evaluation_input.num_windows)

    if evaluation_input.fixed_forecast_window_size == true
        for w in 1:evaluation_input.num_windows
            idx_this_time_series =
                1:(len_original_time_series-evaluation_input.num_steps_ahead-evaluation_input.num_windows+w)
            all_input_series[w] = ObservationSeries(
                original_time_series.names,
                original_time_series.dates[idx_this_time_series],
                original_time_series.observations[idx_this_time_series, :],
            )
        end
    else
        for w in 1:evaluation_input.num_windows
            idx_this_time_series = 1:(len_original_time_series-evaluation_input.num_windows-1+w)
            all_input_series[w] = ObservationSeries(
                original_time_series.names,
                original_time_series.dates[idx_this_time_series],
                original_time_series.observations[idx_this_time_series, :],
            )
        end
    end
    return all_input_series
end

function run_model(
    evaluation_input::EvaluationInput,
    input_series::ObservationSeries,
    tmpdir::String,
    len_original_time_series::Int
)
    input_series_path = joinpath(tmpdir, "_input_time_series.csv")
    output_simulation_path = joinpath(tmpdir, "_simulated_scenarios.csv")
    # write csv with time time_series
    path_input_time_series = write_time_series(input_series_path, input_series)
    # run model with parameters

    if evaluation_input.fixed_forecast_window_size == false
        steps_ahead = minimum([evaluation_input.num_steps_ahead, len_original_time_series - length(input_series.dates)])
    else
        steps_ahead = evaluation_input.num_steps_ahead
    end

    model_cmd = [
        "$(evaluation_input.model_executable_path)",
        "$(path_input_time_series)",
        "$steps_ahead",
        "$(evaluation_input.num_scenarios)",
    ]
    process_result = run(`$model_cmd`)
    if process_result.exitcode != 0
        error("Model execution failed.")
    end
    # read generated scenarios 
    scenarios = load_scenarios(output_simulation_path)
    # delte observations csv and generated scenarios
    rm(input_series_path; force = true)
    rm(output_simulation_path; force = true)
    return scenarios
end

function evaluation_loop(
    evaluation_input::EvaluationInput,
    original_time_series::ObservationSeries,
    results_dir::String
)
    all_input_series = create_all_input_time_series(evaluation_input, original_time_series)
    metrics_dict = OrderedDict()
    tmpdir = mktempdir(
        dirname(evaluation_input.time_series_path);
        prefix = "simulated_scenarios_temp",
        cleanup = true
    )

    len_original_time_series = size(original_time_series.observations, 1)

    for (i, input_series) in enumerate(all_input_series)
        @info("Running model: $(evaluation_input.model_name) on window $i of $(length(all_input_series))")
        scenarios = run_model(evaluation_input, input_series, tmpdir, len_original_time_series)
        push!(metrics_dict, evaluate_metrics(original_time_series, scenarios, i))
        if evaluation_input.plot_all_scenarios_windows
            plot_scenarios(input_series, scenarios, results_dir, evaluation_input, i)
        end
    end
    return metrics_dict
end

function create_results_dir(
            original_time_series::ObservationSeries,
            evaluation_input::EvaluationInput
        )
    reuslts_dir = joinpath(dirname(evaluation_input.time_series_path), "results_$(evaluation_input.model_name)")
    if isdir(reuslts_dir)
        rm(reuslts_dir; force = true, recursive = true)
    end
    results_dir = mkdir(reuslts_dir)
    for serie in original_time_series.names
        mkdir(joinpath(results_dir, serie))
    end
    return results_dir
end

function save_results(metrics_dict::OrderedDict, evaluation_input::EvaluationInput, results_dir::String)
    dict_results = OrderedDict()
    dict_results["inputs"] = OrderedDict()
    dict_results["inputs"]["model_name"] = evaluation_input.model_name
    dict_results["inputs"]["num_steps_ahead"] = evaluation_input.num_steps_ahead
    dict_results["inputs"]["num_scenarios"] = evaluation_input.num_scenarios
    dict_results["inputs"]["num_windows"] = evaluation_input.num_windows
    dict_results["inputs"]["fixed_forecast_window_size"] = evaluation_input.fixed_forecast_window_size
    dict_results["inputs"]["hash_time_series_file"] = calculate_hash_file(evaluation_input.time_series_path)
    dict_results["metrics"] = metrics_dict
    write_json(joinpath(results_dir, "metrics.json"), dict_results)
    return nothing
end

function evaluate_model(parsed_args::Dict)
    evaluation_input = load_evaluation_input(parsed_args["evaluation_config_path"])
    original_time_series = load_time_series(evaluation_input.time_series_path)
    results_dir = create_results_dir(original_time_series, evaluation_input)
    metrics_dict = evaluation_loop(evaluation_input, original_time_series, results_dir)
    save_results(metrics_dict, evaluation_input, results_dir)
    return results_dir
end
