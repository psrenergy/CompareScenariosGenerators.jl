
function generate_tables_mean_metric_by_model(mean_metric_by_model::OrderedDict, results_dir::String)
    models = collect(keys(mean_metric_by_model))
    metrics = collect(keys(collect(values(mean_metric_by_model))[1]))
    agents = collect(keys(collect(values(collect(values(collect(values(mean_metric_by_model))[1]))[1]))[1]))
    num_steps_ahead = length(mean_metric_by_model[models[1]][metrics[1]]["mean"][agents[1]])
    for agent in agents, metric in metrics
        if occursin("sum", metric)
            df_metrics = DataFrame()
            df_metrics[:, "model"] .= []
            df_metrics[:, "statistics"] .= []
            for model_name in models
                output_data = mean_metric_by_model[model_name][metric]["mean"][agent]
                df_aux = DataFrame(model = model_name, statistics = "mean")
                df_aux[!, 2] .= output_data
                append!(df_metrics, df_aux)   
            end
        else
            df_metrics = DataFrame()
            df_metrics[:, "model"] .= []
            df_metrics[:, "statistics"] .= []
            for k in 1:num_steps_ahead
                df_metrics[:, string("K = ",k )] .= []
            end
            for model_name in models
                output_data = mean_metric_by_model[model_name][metric]["IC_LB"][agent]
                df_aux = DataFrame(model = model_name, statistics = "IC_LB")
                for k in 1:num_steps_ahead
                    df_aux[!, string("K = ",k )] .= output_data[k]
                end       
                append!(df_metrics, df_aux)

                output_data = mean_metric_by_model[model_name][metric]["mean"][agent]
                df_aux = DataFrame(model = model_name, statistics = "mean")
                for k in 1:num_steps_ahead
                    df_aux[!, string("K = ",k )] .= output_data[k]
                end       
                append!(df_metrics, df_aux)   
                
                output_data = mean_metric_by_model[model_name][metric]["IC_UB"][agent]
                df_aux = DataFrame(model = model_name, statistics = "IC_UB")
                for k in 1:num_steps_ahead
                    df_aux[!, string("K = ",k )] .= output_data[k]
                end       
                append!(df_metrics, df_aux)              
            end
        end
        CSV.write(string(results_dir, "\\", agent, "_", metric, ".csv"), df_metrics)
    end
    return nothing
end