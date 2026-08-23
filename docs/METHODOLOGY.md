# Methodology

## 1. Data preparation

The raw BTS January 2025 extract contained 539,747 rows and 110 fields. The cleaning workflow retained 41 source fields and created 10 derived variables, yielding 51 analysis-ready columns.

Derived variables include:

- `Airline`
- `IsCancelled`
- `IsDiverted`
- `IsArrivalDelayed15`
- `IsDepartureDelayed15`
- `ScheduledDepHour`
- `DeparturePeriod`
- `DayName`
- `Route`
- `CompletedFlight`

A flight is treated as delayed using the BTS 15-minute threshold.

## 2. SQL analytics

SQLite was used for operational KPI queries, airline/airport rankings, route analysis, delay causes, rolling daily averages, distance bands, and reusable views.

## 3. Statistical inference

Completed non-diverted flights were used for arrival-delay analyses. Major-airline ANOVA was restricted to airlines with at least 5,000 completed flights. Chi-square tests assessed cancellation-airline and departure-period-delay associations. Effect sizes were reported alongside p-values.

The OLS model used a reproducible 120,000-row sample and included departure delay, distance, taxi-out time, taxi-in time, scheduled departure hour, day of week, and airline fixed effects.

## 4. Dashboard

Power BI was used for interactive communication of KPIs and operational patterns. Airport charts use the busiest airports to reduce unstable comparisons driven by low-volume airports.
