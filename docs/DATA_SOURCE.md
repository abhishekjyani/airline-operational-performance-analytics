# Data source

The project uses the **U.S. Bureau of Transportation Statistics (BTS) Reporting Carrier On-Time Performance** dataset for January 2025.

Official BTS TranStats table: Reporting Carrier On-Time Performance (1987-present).

To reproduce the project:

1. Open the BTS TranStats On-Time Performance download page.
2. Select **Year = 2025** and **Month = January**.
3. Download the flight-level CSV.
4. Run `python/01_clean_bts_data.py` against the downloaded CSV.

The analysis uses flight/date, carrier, origin/destination, scheduled and actual times, delay measures, cancellation/diversion indicators, taxi times, distance, and BTS delay-cause fields.

The repository does not redistribute the complete raw or cleaned dataset because the files exceed normal GitHub single-file size limits. The included 25,000-row sample preserves the schema for demonstration.
