using DataFrames
using Statistics
using Dates
using CSV
using StatsModels
using LinearRegression


time_series_path = ARGS[1]
num_steps_ahead = parse(Int, ARGS[2])
num_scenarios = parse(Int, ARGS[3])

# charger le dataframe
df = CSV.read(time_series_path, DataFrame)

HORIZON = num_steps_ahead  # Predict the length of the test dataset

# extraire l'année de chaque date
df[!, "annee"] = year.(df[!, "dates"])

# trouver la valeur maximale de chaque année et calculer la proportion pour chaque mois
max_values = combine(groupby(df, :annee), names(df[:, 2:end]) .=> maximum .=> names(df[:, 2:end]))

proportions = df[:, 2:5] ./ repeat(max_values[:, 2:5], inner=12)[1:size(df, 1), :]

# calculer la moyenne des proportions pour chaque mois
proportions[!, "dates"] = df[!, "dates"]
proportions[!, "month"] = month.(proportions[!, "dates"])
means = combine(groupby(proportions, :month), 
                :NORDESTE => mean,
                :SUDESTE => mean,
                :NORTE => mean,
                :SUL => mean, 
                renamecols=false)

# préparer les données pour la régression linéaire
X = convert(Array, max_values[:, 1])

degree = 2
X_poly = hcat([X.^d for d in 0:degree]...)

predicted_max_values = Vector{Any}()

for year in 0:trunc(Int, ceil(num_steps_ahead / 12)) - 1
    year_value = Vector{Any}()
    for region_nb in 2:5
        y_region = convert(Array, max_values[:, region_nb])
        lr = linregress(X_poly, y_region)
        max_values_pred = maximum(X) + 1 + year
        X_pred = hcat([max_values_pred.^d for d in 0:degree]...)
        max_value = lr(X_pred)
        push!(year_value, max_value[1])
    end
    push!(predicted_max_values, year_value)
end

predicted_max_values = rename(first(repeat(DataFrame(hcat(predicted_max_values...)', :auto), inner = 12), num_steps_ahead),  [:NORDESTE, :SUDESTE, :NORTE, :SUL])

means_values = means[!, 2:5]
means_values = repeat(means_values, outer=Int(ceil(num_steps_ahead / 12))) |> DataFrame

forecast_df = predicted_max_values .* means_values

dates = [df.dates[end-HORIZON] + Dates.Month(HORIZON) + Month(i-1) for i in 1:HORIZON]
scenario = fill(1, nrow(forecast_df))

insertcols!(forecast_df, 1, :dates=>dates)
insertcols!(forecast_df, 2, :scenario=>scenario)

output_path = joinpath(dirname(time_series_path), "_simulated_scenarios.csv")

# Write predictions to a CSV file
CSV.write(output_path, forecast_df, writeheader=true)
