# Idempotent batch reload with audit trail

Synthetic SQL Server case study based on controlled migration reloads. No production names, SQL text, identifiers, or data are included.

## Problem
A failed or corrected batch needs a repeatable reload. Replace only that batch's target rows, validate the staged input, and record counts. A transaction prevents a partially loaded batch from being committed.

## Run
Execute `case.sql` in an empty SQL Server database (SQL Server 2017+). It creates a dedicated `portfolio_reload` schema, fixtures and procedure. It runs batch 101 twice. Both runs leave exactly three rows for batch 101, preserve batch 100, and create two audit records. Run the final SELECTs to verify.

## Production considerations
This small example uses delete and insert inside one transaction. For large tables, evaluate partition switch or bounded transactions with a recovery design, lock duration, transaction log capacity, and foreign keys. Never infer that the demo's three-row throughput extrapolates to millions of rows.
