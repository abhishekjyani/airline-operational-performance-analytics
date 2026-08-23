"""Generate core exploratory-analysis tables and figures from the cleaned BTS CSV."""
import sys
from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

if len(sys.argv) != 3:
    raise SystemExit("Usage: python 02_eda.py <cleaned.csv> <output_dir>")

path, out = Path(sys.argv[1]), Path(sys.argv[2]); out.mkdir(parents=True, exist_ok=True)
df = pd.read_csv(path, low_memory=False, parse_dates=["FlightDate"])
completed = df[df["CompletedFlight"] == 1].copy()

summary = pd.DataFrame({"Metric":[
    "Total flights","Completed flights","Cancelled flights","Diverted flights","Cancellation rate (%)",
    "Arrival delay >=15 min rate among completed (%)","Mean arrival delay, completed (min)",
    "Median arrival delay, completed (min)"],
    "Value":[len(df),df["CompletedFlight"].sum(),df["IsCancelled"].sum(),df["IsDiverted"].sum(),
    100*df["IsCancelled"].mean(),100*completed["IsArrivalDelayed15"].mean(),
    completed["ArrDelay"].mean(),completed["ArrDelay"].median()]})
summary.to_csv(out/'eda_summary.csv', index=False)

air = completed.groupby('Airline').agg(flights=('CompletedFlight','sum'), mean_arr_delay=('ArrDelay','mean'), delay_rate=('IsArrivalDelayed15','mean')).reset_index()
air['delay_rate_pct']=100*air['delay_rate']
air.to_csv(out/'airline_kpis.csv', index=False)

top=air.sort_values('flights',ascending=False).head(12).sort_values('delay_rate_pct')
plt.figure(figsize=(9,5)); plt.barh(top['Airline'],top['delay_rate_pct']); plt.xlabel('Arrival delay >=15 min rate (%)'); plt.ylabel('Airline'); plt.title('Arrival Delay Rate - Largest Airlines, January 2025'); plt.tight_layout(); plt.savefig(out/'airline_delay_rate.png',dpi=220); plt.close()
