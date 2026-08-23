# SQLite setup

The SQL file assumes a SQLite table named `flights` containing the cleaned CSV.

A simple setup with DB Browser for SQLite:

1. Create a database such as `airline_operations.db`.
2. Import `BTS_Jan2025_clean.csv` using **File > Import > Table from CSV file**.
3. Name the table `flights`.
4. Ensure the first row is treated as column names.
5. Run `sql/analysis_queries.sql` in **Execute SQL**.

Optional indexes:

```sql
CREATE INDEX IF NOT EXISTS idx_airline ON flights(Airline);
CREATE INDEX IF NOT EXISTS idx_origin ON flights(Origin);
CREATE INDEX IF NOT EXISTS idx_route ON flights(Route);
CREATE INDEX IF NOT EXISTS idx_date ON flights(FlightDate);
CREATE INDEX IF NOT EXISTS idx_completed ON flights(CompletedFlight);
```
