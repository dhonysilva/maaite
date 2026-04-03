defmodule Maaite.Analytics do
	alias Maaite.DuckLake

	def create_tables! do
    DuckLake.query!("""
      CREATE TABLE IF NOT EXISTS my_ducklake.events (
        id      INTEGER,
        name    VARCHAR,
        payload JSON,
        at      TIMESTAMP DEFAULT now()
      );
    """)
  end

  def insert_event(id, name, payload) do
    DuckLake.query!(
      "INSERT INTO my_ducklake.events VALUES (?, ?, ?);",
      [id, name, Jason.encode!(payload)]
    )
  end

  def recent_events(limit \\ 50) do
    DuckLake.query_maps(
      "SELECT * FROM my_ducklake.events ORDER BY at DESC LIMIT ?;",
      [limit]
    )
  end
end
