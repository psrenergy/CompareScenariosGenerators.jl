import pandas as pd
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import PolynomialFeatures
import os
import sys
import numpy as np
from dateutil.relativedelta import relativedelta


time_series_path = sys.argv[1]
num_steps_ahead = int(sys.argv[2])
num_scenarios = int(sys.argv[3])


# charger le dataframe
df = pd.read_csv(time_series_path)

HORIZON = num_steps_ahead  # Predict the length of the test dataset

# convertir la colonne des dates en format de date
df['dates'] = pd.to_datetime(df['dates'])

# extraire l'année de chaque date
df['annee'] = df['dates'].dt.year

# trouver la valeur maximale de chaque année et calculer la proportion pour chaque mois
max_values = df.groupby(['annee']).max()

proportions = df.iloc[:, 1:5].div(max_values.iloc[:, 1:5].values.repeat(
    12, axis=0)[:df.shape[0]])  # diviser les valeurs par les maxima

# calculer la moyenne des proportions pour chaque mois
proportions.index = pd.to_datetime(df.iloc[:, 0], format='%Y-%m-%d')
means = proportions.groupby(proportions.index.month).mean()

# préparer les données pour la régression linéaire
X = max_values.index.values.reshape(-1, 1)
y = max_values.iloc[:, 1:5].values

# Créer des caractéristiques polynomiales de degré 2
poly = PolynomialFeatures(degree=2)
# Appliquer les caractéristiques polynomiales à X
X_poly = poly.fit_transform(X)

predicted_max_values = []

for year in range(int(np.ceil(num_steps_ahead / 12))):
    year_value = []
    for region_nb in range(4):
        y_region = y[:, region_nb]
        reg = LinearRegression().fit(X_poly, y_region)
        max_values_pred = max_values.index.max() + 1 + year
        X_pred = poly.transform(max_values_pred.reshape(-1, 1))
        max_value = reg.predict(X_pred)
        year_value.append(max_value[0])
    predicted_max_values.append(year_value)

df_predicted_max_value = pd.DataFrame(predicted_max_values).values.repeat(12, axis = 0)[:num_steps_ahead]

means_values = means.reset_index().iloc[:, 1:5]
means_values = pd.concat([means_values] * int(np.ceil(num_steps_ahead / 12)), ignore_index=True)

forecast_df = df_predicted_max_value * means_values

dates = [date + np.timedelta64(HORIZON, 'M') for date in df['dates'].iloc[-HORIZON:].values.astype('datetime64[M]')]

forecast_df.insert(0, 'dates',  dates)
forecast_df.insert(1, 'scenario', 1)

output_path = os.path.join(os.path.dirname(
    time_series_path), "_simulated_scenarios.csv")

# Write predictions to a CSV file
forecast_df.to_csv(output_path, index=False)
