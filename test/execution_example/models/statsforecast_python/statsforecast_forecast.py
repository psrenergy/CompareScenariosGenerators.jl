import sys
import pandas as pd
from statsforecast import StatsForecast
from statsforecast.models import AutoARIMA
import os


time_series_path = sys.argv[1]
num_steps_ahead = int(sys.argv[2])
num_scenarios = int(sys.argv[3])

# Load CSV data into a DataFrame
df = pd.read_csv(time_series_path)

# Define constants for seasonality and prediction period
SEASON_LENGTH = 12  # Monthly data
HORIZON = num_steps_ahead  # Predict the length of the test dataset

# Define list of models to use
models = [AutoARIMA(season_length=SEASON_LENGTH)]

# Create DataFrame for predictions
forecast_df = pd.DataFrame()

# Loop over geographic zones to predict
for zone_name in ["SUDESTE", "NORDESTE", "SUL", "NORTE"]:
    # Select date and zone columns
    df_zone = df[["dates", zone_name]]
    # Rename columns for standardized names
    df_zone.columns = ['ds', 'y']
    df_zone = df_zone.assign(unique_id=1.0)
    
    # Instantiate StatsForecast class with current zone data
    sf = StatsForecast(df=df_zone, models=models, freq='MS', n_jobs=-1)
    # Predict for the period defined by HORIZON
    Y_hat_df = sf.forecast(HORIZON)
    # Drop the "unique_id" column
    Y_hat_df = Y_hat_df.reset_index().drop("unique_id", axis=1)
    
    # Add predictions for the current zone to the global DataFrame
    forecast_df[zone_name] = Y_hat_df["AutoARIMA"]

# Add "dates" and "scenarios" columns to the global DataFrame
forecast_df.insert(1, 'dates', Y_hat_df["ds"])
forecast_df.insert(2, 'scenario', 1)

output_path = os.path.join(os.path.dirname(time_series_path), "_simulated_scenarios.csv")

# Write predictions to a CSV file
forecast_df.to_csv(output_path, index=False)
