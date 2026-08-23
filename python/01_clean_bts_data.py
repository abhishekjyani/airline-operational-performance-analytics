"""Clean a BTS On-Time Performance CSV for the airline analytics project.
Usage: python 01_clean_bts_data.py raw.csv cleaned.csv
"""
import sys
import numpy as np
import pandas as pd

if len(sys.argv) != 3:
    raise SystemExit("Usage: python 01_clean_bts_data.py <raw.csv> <cleaned.csv>")

raw_path, out_path = sys.argv[1], sys.argv[2]
df = pd.read_csv(raw_path, low_memory=False)

keep = [
    "Year","Quarter","Month","DayofMonth","DayOfWeek","FlightDate",
    "Reporting_Airline","IATA_CODE_Reporting_Airline","Tail_Number",
    "Flight_Number_Reporting_Airline","Origin","OriginCityName","OriginState",
    "Dest","DestCityName","DestState","CRSDepTime","DepTime","DepDelay",
    "DepDelayMinutes","DepDel15","CRSArrTime","ArrTime","ArrDelay",
    "ArrDelayMinutes","ArrDel15","Cancelled","CancellationCode","Diverted",
    "CRSElapsedTime","ActualElapsedTime","AirTime","Flights","Distance",
    "TaxiOut","TaxiIn","CarrierDelay","WeatherDelay","NASDelay",
    "SecurityDelay","LateAircraftDelay"
]
missing = [c for c in keep if c not in df.columns]
if missing:
    raise ValueError(f"Missing expected columns: {missing}")

clean = df[keep].copy()
clean["FlightDate"] = pd.to_datetime(clean["FlightDate"], errors="coerce")
clean["Airline"] = clean["IATA_CODE_Reporting_Airline"].fillna(clean["Reporting_Airline"])
clean["IsCancelled"] = clean["Cancelled"].fillna(0).astype(int)
clean["IsDiverted"] = clean["Diverted"].fillna(0).astype(int)
clean["IsArrivalDelayed15"] = clean["ArrDel15"].fillna((clean["ArrDelayMinutes"] >= 15).astype(float))
clean["IsDepartureDelayed15"] = clean["DepDel15"].fillna((clean["DepDelayMinutes"] >= 15).astype(float))

def hhmm_to_hour(x):
    if pd.isna(x): return np.nan
    x = int(x)
    return 0 if x == 2400 else x // 100

clean["ScheduledDepHour"] = clean["CRSDepTime"].apply(hhmm_to_hour)

def time_band(h):
    if pd.isna(h): return np.nan
    if 5 <= h < 10: return "Early Morning"
    if 10 <= h < 15: return "Late Morning"
    if 15 <= h < 19: return "Afternoon"
    if 19 <= h < 24: return "Evening"
    return "Night"

clean["DeparturePeriod"] = clean["ScheduledDepHour"].apply(time_band)
clean["DayName"] = clean["DayOfWeek"].map({1:"Monday",2:"Tuesday",3:"Wednesday",4:"Thursday",5:"Friday",6:"Saturday",7:"Sunday"})
clean["Route"] = clean["Origin"].astype(str) + "-" + clean["Dest"].astype(str)
clean["CompletedFlight"] = ((clean["IsCancelled"] == 0) & (clean["IsDiverted"] == 0)).astype(int)
clean = clean.drop_duplicates()
clean.to_csv(out_path, index=False)
print(f"Wrote {len(clean):,} rows and {len(clean.columns)} columns to {out_path}")
