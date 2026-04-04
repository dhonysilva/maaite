defmodule Maaite.Analytics do
  alias Maaite.DuckLake

  def create_tables! do
    DuckLake.query!("""
      CREATE TABLE IF NOT EXISTS my_ducklake.events (
        id      INTEGER,
        name    VARCHAR,
        payload JSON,
        inserted_at      TIMESTAMP DEFAULT now()
      );
    """)

    DuckLake.query!("""
      CREATE TABLE IF NOT EXISTS my_ducklake.train_stations AS
      FROM 'https://blobs.duckdb.org/nl_stations.csv';
    """)

    DuckLake.query!("""
      CREATE TABLE IF NOT EXISTS my_ducklake.services AS
      SELECT
        "Service:Company" as service_company,
        "Service:Completely cancelled" as service_completely_cancelled,
        "Service:Date" as service_date,
        "Service:Maximum delay" as service_maximum_delay,
        "Service:Partly cancelled" as service_partly_cancelled,
        "Service:RDT-ID" as service_rdt_id,
        "Service:Train number" as service_train_number,
        "Service:Type" as service_type,
        "Stop:Arrival cancelled" as stop_arrival_cancelled,
        "Stop:Arrival delay" as stop_arrival_delay,
        "Stop:Arrival time" as stop_arrival_time,
        "Stop:Departure cancelled" as stop_departure_cancelled,
        "Stop:Departure delay" as stop_departure_delay,
        "Stop:Departure time" as stop_departure_time,
        "Stop:RDT-ID" as stop_rdt_id,
        "Stop:Station code" as stop_station_code,
        "Stop:Station name" as stop_station_name

      FROM 'https://blobs.duckdb.org/nl-railway/services-2023.csv.gz';
    """)

    :ok
  end

  def insert_event(id, name, payload) do
    DuckLake.query!(
      "INSERT INTO my_ducklake.events VALUES (?, ?, ?);",
      [id, name, Jason.encode!(payload)]
    )
  end

  def recent_events(limit \\ 50) do
    DuckLake.query_maps(
      "SELECT * FROM my_ducklake.events ORDER BY inserted_at DESC LIMIT ?;",
      [limit]
    )
  end
end
