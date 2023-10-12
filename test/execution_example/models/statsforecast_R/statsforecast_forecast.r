library(forecast)
library(dplyr)
library(tidyr)


args <- commandArgs(trailingOnly = TRUE)
time_series_path <- args[1]
num_steps_ahead <- as.integer(args[2])
num_scenarios <- as.integer(args[3])


# Load CSV data into a DataFrame
df <- read.csv(time_series_path)

# Define constants for seasonality and prediction period
SEASON_LENGTH <- 12  # Monthly data
HORIZON <- num_steps_ahead  # Predict the length of the test dataset

# Create list of models to use
models <- list(auto.arima = forecast::auto.arima)

# Create DataFrame for predictions
forecast_df <- data.frame(dates = seq(as.Date(Sys.time()), by = "month", length.out = HORIZON), stringsAsFactors = FALSE) # nolint

dates <- tail(df$dates, HORIZON)
forecast_df$dates <- dates

scenario_col <- rep(1, nrow(forecast_df))
forecast_df <- cbind(forecast_df, scenario_col)
colnames(forecast_df)[2] <- "scenario"

# Loop over geographic zones to predict
for (zone_name in c("SUDESTE", "NORDESTE", "SUL", "NORTE")) {
  # Select date and zone columns
  df_zone <- df[, c("dates", zone_name)]
  # Rename columns for standardized names
  colnames(df_zone) <- c("ds", "y")
  df_zone$unique_id <- 1.0

  # Fit a model to the data
  model <- auto.arima(df_zone$y, seasonal = TRUE)

  # Predict for the period defined by HORIZON
  y_hat_df <- forecast(model, h = HORIZON)
  forecast_df[zone_name] <- y_hat_df["mean"]
}

# Write predictions to a CSV file
output_path <- paste0(dirname(time_series_path), "/_simulated_scenarios.csv")
write.csv(forecast_df, file = output_path, row.names = FALSE)