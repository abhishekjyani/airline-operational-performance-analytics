
-- ============================================================
-- Airline Operational Performance Analytics
-- Dataset: BTS January 2025
-- Database: SQLite
-- Table: flights
-- ============================================================

-- 1. OVERALL KPI SUMMARY
SELECT
    COUNT(*) AS total_flights,
    SUM(IsCancelled) AS cancelled_flights,
    ROUND(100.0 * AVG(IsCancelled), 2) AS cancellation_rate_pct,
    SUM(IsDiverted) AS diverted_flights,
    SUM(CompletedFlight) AS completed_flights,
    ROUND(100.0 * AVG(CASE WHEN CompletedFlight = 1 THEN IsArrivalDelayed15 END), 2) AS arrival_delay15_rate_pct,
    ROUND(AVG(CASE WHEN CompletedFlight = 1 THEN ArrDelay END), 2) AS mean_arrival_delay_min,
    ROUND(AVG(CASE WHEN CompletedFlight = 1 THEN DepDelay END), 2) AS mean_departure_delay_min
FROM flights;


-- 2. AIRLINE PERFORMANCE RANKING
SELECT
    Airline,
    COUNT(*) AS total_flights,
    SUM(IsCancelled) AS cancellations,
    ROUND(100.0 * AVG(IsCancelled), 2) AS cancellation_rate_pct,
    ROUND(AVG(CASE WHEN CompletedFlight = 1 THEN ArrDelay END), 2) AS mean_arrival_delay_min,
    ROUND(
        100.0 * AVG(
            CASE WHEN CompletedFlight = 1 THEN IsArrivalDelayed15 END
        ), 2
    ) AS arrival_delay15_rate_pct
FROM flights
GROUP BY Airline
ORDER BY arrival_delay15_rate_pct DESC;


-- 3. AIRLINE CANCELLATION RANKING
SELECT
    Airline,
    COUNT(*) AS total_flights,
    SUM(IsCancelled) AS cancelled_flights,
    ROUND(100.0 * SUM(IsCancelled) / COUNT(*), 2) AS cancellation_rate_pct
FROM flights
GROUP BY Airline
HAVING COUNT(*) >= 1000
ORDER BY cancellation_rate_pct DESC;


-- 4. ORIGIN AIRPORT DELAY PERFORMANCE
SELECT
    Origin,
    COUNT(*) AS total_departures,
    ROUND(AVG(CASE WHEN CompletedFlight = 1 THEN DepDelay END), 2) AS mean_departure_delay_min,
    ROUND(
        100.0 * AVG(
            CASE WHEN CompletedFlight = 1 THEN IsDepartureDelayed15 END
        ), 2
    ) AS departure_delay15_rate_pct
FROM flights
GROUP BY Origin
HAVING COUNT(*) >= 1000
ORDER BY departure_delay15_rate_pct DESC;


-- 5. BUSIEST ROUTES
SELECT
    Route,
    Origin,
    Dest,
    COUNT(*) AS total_flights,
    ROUND(AVG(CASE WHEN CompletedFlight = 1 THEN ArrDelay END), 2) AS mean_arrival_delay_min,
    ROUND(
        100.0 * AVG(
            CASE WHEN CompletedFlight = 1 THEN IsArrivalDelayed15 END
        ), 2
    ) AS arrival_delay15_rate_pct
FROM flights
GROUP BY Route, Origin, Dest
ORDER BY total_flights DESC
LIMIT 20;


-- 6. DELAY BY DEPARTURE PERIOD
SELECT
    DeparturePeriod,
    COUNT(*) AS completed_flights,
    ROUND(AVG(ArrDelay), 2) AS mean_arrival_delay_min,
    ROUND(100.0 * AVG(IsArrivalDelayed15), 2) AS arrival_delay15_rate_pct
FROM flights
WHERE CompletedFlight = 1
GROUP BY DeparturePeriod
ORDER BY
    CASE DeparturePeriod
        WHEN 'Early Morning' THEN 1
        WHEN 'Late Morning' THEN 2
        WHEN 'Afternoon' THEN 3
        WHEN 'Evening' THEN 4
        WHEN 'Night' THEN 5
    END;


-- 7. DELAY BY DAY OF WEEK
SELECT
    DayName,
    COUNT(*) AS completed_flights,
    ROUND(AVG(ArrDelay), 2) AS mean_arrival_delay_min,
    ROUND(100.0 * AVG(IsArrivalDelayed15), 2) AS arrival_delay15_rate_pct
FROM flights
WHERE CompletedFlight = 1
GROUP BY DayName
ORDER BY
    CASE DayName
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;


-- 8. DELAY CAUSE CONTRIBUTION
WITH causes AS (
    SELECT 'Carrier Delay' AS cause, SUM(CarrierDelay) AS delay_minutes FROM flights
    UNION ALL
    SELECT 'Weather Delay', SUM(WeatherDelay) FROM flights
    UNION ALL
    SELECT 'NAS Delay', SUM(NASDelay) FROM flights
    UNION ALL
    SELECT 'Security Delay', SUM(SecurityDelay) FROM flights
    UNION ALL
    SELECT 'Late Aircraft Delay', SUM(LateAircraftDelay) FROM flights
),
total AS (
    SELECT SUM(delay_minutes) AS total_delay_minutes
    FROM causes
)
SELECT
    cause,
    ROUND(delay_minutes, 0) AS total_delay_minutes,
    ROUND(100.0 * delay_minutes / total_delay_minutes, 2) AS share_pct
FROM causes, total
ORDER BY delay_minutes DESC;


-- 9. AIRLINE RANK USING WINDOW FUNCTIONS
WITH airline_perf AS (
    SELECT
        Airline,
        COUNT(*) AS total_flights,
        ROUND(
            100.0 * AVG(
                CASE WHEN CompletedFlight = 1 THEN IsArrivalDelayed15 END
            ), 2
        ) AS arrival_delay15_rate_pct
    FROM flights
    GROUP BY Airline
)
SELECT
    Airline,
    total_flights,
    arrival_delay15_rate_pct,
    RANK() OVER (ORDER BY arrival_delay15_rate_pct ASC) AS best_on_time_rank
FROM airline_perf
ORDER BY best_on_time_rank;


-- 10. AIRPORT RANKING WITH TRAFFIC THRESHOLD
WITH airport_perf AS (
    SELECT
        Origin AS airport,
        COUNT(*) AS total_flights,
        ROUND(
            100.0 * AVG(
                CASE WHEN CompletedFlight = 1 THEN IsDepartureDelayed15 END
            ), 2
        ) AS departure_delay15_rate_pct
    FROM flights
    GROUP BY Origin
    HAVING COUNT(*) >= 2000
)
SELECT
    airport,
    total_flights,
    departure_delay15_rate_pct,
    DENSE_RANK() OVER (
        ORDER BY departure_delay15_rate_pct ASC
    ) AS performance_rank
FROM airport_perf
ORDER BY performance_rank;


-- 11. DAILY DELAY TREND + 7-DAY ROLLING AVERAGE
WITH daily AS (
    SELECT
        FlightDate,
        ROUND(AVG(CASE WHEN CompletedFlight = 1 THEN ArrDelay END), 2) AS avg_arr_delay
    FROM flights
    GROUP BY FlightDate
)
SELECT
    FlightDate,
    avg_arr_delay,
    ROUND(
        AVG(avg_arr_delay) OVER (
            ORDER BY FlightDate
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ), 2
    ) AS rolling_7day_avg_arr_delay
FROM daily
ORDER BY FlightDate;


-- 12. CANCELLATION BREAKDOWN USING CASE WHEN
SELECT
    CASE
        WHEN CancellationCode = 'A' THEN 'Carrier'
        WHEN CancellationCode = 'B' THEN 'Weather'
        WHEN CancellationCode = 'C' THEN 'National Air System'
        WHEN CancellationCode = 'D' THEN 'Security'
        ELSE 'Not Cancelled / Unknown'
    END AS cancellation_reason,
    COUNT(*) AS flights
FROM flights
WHERE IsCancelled = 1
GROUP BY cancellation_reason
ORDER BY flights DESC;


-- 13. ROUTES WITH HIGH DELAY RATE, CONTROLLING FOR LOW SAMPLE SIZE
SELECT
    Route,
    COUNT(*) AS completed_flights,
    ROUND(AVG(ArrDelay), 2) AS mean_arrival_delay_min,
    ROUND(100.0 * AVG(IsArrivalDelayed15), 2) AS arrival_delay15_rate_pct
FROM flights
WHERE CompletedFlight = 1
GROUP BY Route
HAVING COUNT(*) >= 300
ORDER BY arrival_delay15_rate_pct DESC
LIMIT 20;


-- 14. DISTANCE-BAND PERFORMANCE
SELECT
    CASE
        WHEN Distance < 500 THEN '<500 miles'
        WHEN Distance < 1000 THEN '500-999 miles'
        WHEN Distance < 1500 THEN '1000-1499 miles'
        WHEN Distance < 2000 THEN '1500-1999 miles'
        ELSE '2000+ miles'
    END AS distance_band,
    COUNT(*) AS completed_flights,
    ROUND(AVG(ArrDelay), 2) AS mean_arrival_delay_min,
    ROUND(100.0 * AVG(IsArrivalDelayed15), 2) AS arrival_delay15_rate_pct
FROM flights
WHERE CompletedFlight = 1
GROUP BY distance_band
ORDER BY MIN(Distance);


-- 15. CREATE REUSABLE AIRLINE KPI VIEW
DROP VIEW IF EXISTS airline_kpi_view;

CREATE VIEW airline_kpi_view AS
SELECT
    Airline,
    COUNT(*) AS total_flights,
    SUM(IsCancelled) AS cancelled_flights,
    ROUND(100.0 * AVG(IsCancelled), 2) AS cancellation_rate_pct,
    ROUND(AVG(CASE WHEN CompletedFlight = 1 THEN ArrDelay END), 2) AS mean_arrival_delay_min,
    ROUND(
        100.0 * AVG(
            CASE WHEN CompletedFlight = 1 THEN IsArrivalDelayed15 END
        ), 2
    ) AS arrival_delay15_rate_pct
FROM flights
GROUP BY Airline;

-- View usage:
SELECT * FROM airline_kpi_view
ORDER BY arrival_delay15_rate_pct ASC;
