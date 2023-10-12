function report_metrics(parsed_args::Dict{String, Any})
    # Gather results from different models
    mean_of_metric_by_model = evaluate_mean_of_metric_by_model(parsed_args["model_execution_jsons"])
    sum_of_mean_metrics_by_series = evaluate_sum_of_mean_metric_by_series(mean_of_metric_by_model)

    # Plot results
    results_dir = joinpath(pwd(), "Compare_Scenarios_Reports")
    if isdir(results_dir)
        rm(results_dir; force = true, recursive = true)
    end
    mkdir(results_dir)
    plot_mean_metric_by_model(mean_of_metric_by_model, results_dir)
    plot_sum_of_mean_metrics_by_series(sum_of_mean_metrics_by_series, results_dir)
    generate_tables_mean_metric_by_model(mean_of_metric_by_model, results_dir)
    return nothing
end

function evaluate_mean_of_metric_by_model(files::Vector{String})
    mean_of_metric_by_model = OrderedDict()
    hashes_of_input_files = String[]
    for file in files
        @assert isfile(file)
        model_metrics_dict = JSON.parsefile(file; dicttype=OrderedDict)
        
        mean_of_metric_by_model[model_metrics_dict["inputs"]["model_name"]] = take_mean_over_windows(model_metrics_dict["metrics"], model_metrics_dict["inputs"]["fixed_forecast_window_size"])

        push!(hashes_of_input_files, model_metrics_dict["inputs"]["hash_time_series_file"])
    end
    @assert length(unique(hashes_of_input_files)) == 1
    return mean_of_metric_by_model
end

function take_mean_over_windows(model_metrics_dict::OrderedDict, fixed_forecast_window_size::Bool)
    mean_of_metrics = OrderedDict()
    metrics = collect(keys(model_metrics_dict["1"]))
    agents = collect(keys(model_metrics_dict["1"][metrics[1]]))
    num_steps_ahead = length(model_metrics_dict["1"][metrics[1]][agents[1]])
    num_windows = length(collect(keys(model_metrics_dict)))
    # Create empty vectors
    for metric in metrics
        mean_of_metrics[metric] = OrderedDict()
        mean_of_metrics[metric]["mean"] = OrderedDict()
        mean_of_metrics[metric]["IC_LB"] = OrderedDict()
        mean_of_metrics[metric]["IC_UB"] = OrderedDict()
        for agent in agents
            if occursin("sum", metric)
                mean_of_metrics[metric]["mean"][agent] = zeros(Float64)
            else
                mean_of_metrics[metric]["mean"][agent] = zeros(Float64, num_steps_ahead)
                mean_of_metrics[metric]["IC_LB"][agent] = zeros(Float64, num_steps_ahead)
                mean_of_metrics[metric]["IC_UB"][agent] = zeros(Float64, num_steps_ahead)
            end
        end
    end

    # Fill with mean of metrics

    for dict in values(model_metrics_dict), metric in metrics, agent in agents
        if occursin("sum", metric)
            mean_of_metrics[metric]["mean"][agent] += [dict[metric][agent]] / num_windows
        else
            mean_of_metrics[metric]["mean"][agent][1:length(dict[metric][agent])] += dict[metric][agent] #./ num_windows
        end
    end
    
    if fixed_forecast_window_size == false
        for metric in metrics, agent in agents
            if occursin("sum", metric) == false
                for k in 1:num_steps_ahead
                    mean_of_metrics[metric]["mean"][agent][k] = deepcopy(mean_of_metrics[metric]["mean"][agent][k]) / (num_windows - k + 1)
                end
            end
        end    
    else
        if occursin("sum", metric) == false
            for metric in metrics, agent in agents
                mean_of_metrics[metric]["mean"][agent] = deepcopy(mean_of_metrics[metric]["mean"][agent]) / num_windows
            end  
        end
    end

    # Calcula IC do bias
    metric = "bias"
    if fixed_forecast_window_size == false
        for agent in agents
            for k in 1:num_steps_ahead
                n = num_windows - (k - 1)
                aux = zeros(n)
                for i in 1:n
                    aux[i] = model_metrics_dict[string(i)][metric][agent][k]
                end
                autocov_vector = autocov(aux, 0:n-1)
                v = sum((1 - h/sqrt(n))*autocov_vector[Int(h+1)] for h in 0:sqrt(n))
                mean_of_metrics[metric]["IC_LB"][agent][k] = mean_of_metrics[metric]["mean"][agent][k] - 1.96*sqrt(v/n)              
                mean_of_metrics[metric]["IC_UB"][agent][k] = mean_of_metrics[metric]["mean"][agent][k] + 1.96*sqrt(v/n)
            end
        end
    end


    return mean_of_metrics
end

function evaluate_sum_of_mean_metric_by_series(mean_of_metric_by_model::OrderedDict)
    sum_of_mean_metric = OrderedDict()
    for (model_name, mean_metric_dict) in mean_of_metric_by_model
        sum_of_mean_metric[model_name] = OrderedDict()
        for (metric, series_metrics) in mean_metric_dict
            sum_of_mean_metric[model_name][metric] = sum(v for (k, v) in series_metrics["mean"])
        end
    end
    return sum_of_mean_metric
end
