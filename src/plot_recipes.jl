function save_plot(p, filename::String)
    open(filename, "w") do io
        show(io, "text/html", p)
    end
    return filename
end

function plot_scenarios(
                input_series::ObservationSeries, 
                scenarios::ScenariosSeries, 
                results_dir::String, 
                evaluation_input::EvaluationInput, 
                window::Int
            )
    for (i, agent) in enumerate(input_series.names)
        layout = Layout(
            title = evaluation_input.model_name * " - " * agent,
            xaxis_title = "Month",
            yaxis_title = "MW",
            plot_bgcolor = "white",
            yaxis_range=[0, 1.5*maximum(input_series.observations[:, i])]
        )
        observation_trace = scatter(
            x = input_series.dates, 
            y = input_series.observations[:, i], 
            line = attr(color="black", width=2), 
            name = "observed"
        )
        scenarios_traces = GenericTrace[]
        for j in axes(scenarios.scenarios[:, i, :], 2)
            push!(scenarios_traces, 
                scatter(
                    x = scenarios.dates, 
                    y = scenarios.scenarios[:, i, j], 
                    line = attr(color="grey", width=0.2), 
                    name="scenario $j"
                )
            )
        end
        p = PlotlyJS.plot(vcat(observation_trace, scenarios_traces), layout);
        PlotlyJS.savefig(p, joinpath(results_dir, agent, "$(agent)_$(window).html"))
    end
    return nothing
end

function plot_mean_metric_by_model(mean_metric_by_model::OrderedDict, results_dir::String)
    # TODO improve this logics of querying agent names and metrics
    models = collect(keys(mean_metric_by_model))
    metrics = collect(keys(collect(values(mean_metric_by_model))[1]))
    agents = collect(keys(collect(values(collect(values(collect(values(mean_metric_by_model))[1]))[1]))[1]))
    for agent in agents, metric in metrics
        if occursin("sum", metric) == false
            layout = Layout(
                title = metric * " - " * agent,
                xaxis_title = "steps ahead",
                plot_bgcolor = "white",
            )
            metric_traces = GenericTrace[]
            for model_name in models
                push!(metric_traces,
                    scatter(
                        x = 1:length(mean_metric_by_model[model_name][metric]["mean"][agent]),
                        y = mean_metric_by_model[model_name][metric]["mean"][agent], 
                        line = attr(width=2), 
                        name = model_name
                    )
                )
            end
            p = PlotlyJS.plot(metric_traces, layout)
            PlotlyJS.savefig(p, joinpath(results_dir, "$(agent)_$(metric).html"))
        end
    end
    return nothing
end

function plot_sum_of_mean_metrics_by_series(sum_of_mean_metrics_by_series::OrderedDict, results_dir::String)
    models = collect(keys(sum_of_mean_metrics_by_series))
    metrics = collect(keys(collect(values(sum_of_mean_metrics_by_series))[1]))
    for metric in metrics
        if occursin("sum", metric) == false
            layout = Layout(
                title = metric,
                xaxis_title = "steps ahead",
                plot_bgcolor = "white",
            )
            metric_traces = GenericTrace[]
            for model_name in models
                push!(metric_traces,
                    scatter(
                        x = 1:length(sum_of_mean_metrics_by_series[model_name][metric]),
                        y = sum_of_mean_metrics_by_series[model_name][metric], 
                        line = attr(width=2), 
                        name = model_name
                    )
                )
            end
            p = PlotlyJS.plot(metric_traces, layout)
            PlotlyJS.savefig(p, joinpath(results_dir, "$(metric)_summary.html"))
        end
    end
    return nothing
end