function find_correct_idx_to_compare(
    original_time_series::ObservationSeries, 
    scenarios::ScenariosSeries, 
)
    dates_to_compare = scenarios.dates
    idx = findall(x -> x in dates_to_compare, original_time_series.dates)
    @assert length(idx) == length(dates_to_compare)
    return idx
end

function evaluate_metrics(
    original_time_series::ObservationSeries, 
    scenarios::ScenariosSeries, 
    window::Int
)
    metrics = OrderedDict()
    metrics["bias"] = evaluate_bias(original_time_series, scenarios)
    metrics["bias_sum"] = evaluate_bias_sum(original_time_series, scenarios)
    metrics["mae"] = evaluate_mae(original_time_series, scenarios)
    metrics["mae_sum"] = evaluate_mae_sum(original_time_series, scenarios)
    metrics["crps"] = evaluate_crps(original_time_series, scenarios)
    metrics["crps_sum"] = evaluate_crps_sum(original_time_series, scenarios)

    return Pair(window, metrics)
end

function evaluate_bias(
    original_time_series::ObservationSeries, 
    scenarios::ScenariosSeries
)
    num_agents = size(scenarios.scenarios, 2)
    num_timesteps = length(scenarios.dates)
    bias = OrderedDict()
    idx = find_correct_idx_to_compare(original_time_series, scenarios)
    for agent in 1:num_agents
        bias[original_time_series.names[agent]] = Vector{Float64}(undef, num_timesteps)
        for (scenario_t, observation_t) in enumerate(idx)
            bias[original_time_series.names[agent]][scenario_t] = mean(scenarios.scenarios[scenario_t, agent, :]) - original_time_series.observations[observation_t, agent]
        end
    end
    return bias
end

function evaluate_bias_sum(
    original_time_series::ObservationSeries, 
    scenarios::ScenariosSeries
)
    num_agents = size(scenarios.scenarios, 2)
    num_timesteps = length(scenarios.dates)
    bias_sum = OrderedDict()
    idx = find_correct_idx_to_compare(original_time_series, scenarios)
    for agent in 1:num_agents
        bias_sum[original_time_series.names[agent]] = Vector{Float64}(undef, num_timesteps)

        forecast_sum = 0
        observed_sum = 0

        for (scenario_t, observation_t) in enumerate(idx)
            forecast_sum += mean(scenarios.scenarios[scenario_t, agent, :])
            observed_sum += original_time_series.observations[observation_t, agent]
        end
        bias_sum[original_time_series.names[agent]] = forecast_sum - observed_sum
    end
    return bias_sum
end

function evaluate_mae(
    original_time_series::ObservationSeries, 
    scenarios::ScenariosSeries
)
    num_agents = size(scenarios.scenarios, 2)
    num_timesteps = length(scenarios.dates)
    mae = OrderedDict()
    idx = find_correct_idx_to_compare(original_time_series, scenarios)
    for agent in 1:num_agents
        mae[original_time_series.names[agent]] = Vector{Float64}(undef, num_timesteps)
        for (scenario_t, observation_t) in enumerate(idx)
            mae[original_time_series.names[agent]][scenario_t] = abs(median(scenarios.scenarios[scenario_t, agent, :]) - original_time_series.observations[observation_t, agent])
        end
    end
    return mae
end

function evaluate_mae_sum(
    original_time_series::ObservationSeries, 
    scenarios::ScenariosSeries
)
    num_agents = size(scenarios.scenarios, 2)
    num_timesteps = length(scenarios.dates)
    mae_sum = OrderedDict()
    idx = find_correct_idx_to_compare(original_time_series, scenarios)
    for agent in 1:num_agents
        mae_sum[original_time_series.names[agent]] = Vector{Float64}(undef, num_timesteps)

        forecast_sum = 0
        observed_sum = 0

        for (scenario_t, observation_t) in enumerate(idx)
            forecast_sum += median(scenarios.scenarios[scenario_t, agent, :])
            observed_sum += original_time_series.observations[observation_t, agent]
        end
        mae_sum[original_time_series.names[agent]] = abs(forecast_sum - observed_sum)
    end
    return mae_sum
end

discrete_crps_indicator_function(val::Float64, z::Float64) = val < z
function evaluate_crps(val::Float64, scenarios::Vector{Float64})
    sorted_scenarios = sort(scenarios)
    m = length(scenarios)
    crps_score = zero(Float64)
    for i = 1:m
        crps_score +=
            (sorted_scenarios[i] - val) *
            (m * discrete_crps_indicator_function(val, sorted_scenarios[i]) - i + 0.5)
    end
    return (2 / m^2) * crps_score
end
function evaluate_crps(
    original_time_series::ObservationSeries, 
    scenarios::ScenariosSeries
)
    num_agents = size(scenarios.scenarios, 2)
    num_timesteps = length(scenarios.dates)
    crps = OrderedDict()
    idx = find_correct_idx_to_compare(original_time_series, scenarios)
    for agent in 1:num_agents
        crps[original_time_series.names[agent]] = Vector{Float64}(undef, num_timesteps)
        for (scenario_t, observation_t) in enumerate(idx)
            crps[original_time_series.names[agent]][scenario_t] = evaluate_crps(
                original_time_series.observations[observation_t, agent], 
                scenarios.scenarios[scenario_t, agent, :]
            )
        end
    end
    return crps
end

function evaluate_crps_sum(
    original_time_series::ObservationSeries, 
    scenarios::ScenariosSeries
)
    num_agents = size(scenarios.scenarios, 2)
    num_timesteps = length(scenarios.dates)
    num_scenarios = size(scenarios.scenarios, 3)
    crps_sum = OrderedDict()
    idx = find_correct_idx_to_compare(original_time_series, scenarios)
    for agent in 1:num_agents
        crps_sum[original_time_series.names[agent]] = Vector{Float64}(undef, 1)
        scenarios_sum = zeros(num_scenarios)
        observation_sum = 0
        for (scenario_t, observation_t) in enumerate(idx)
            scenarios_sum += scenarios.scenarios[scenario_t, agent, :]
            observation_sum += original_time_series.observations[observation_t, agent]
        end
        crps_sum[original_time_series.names[agent]] = evaluate_crps(
            observation_sum, 
            scenarios_sum
        )
    end
    return crps_sum
end