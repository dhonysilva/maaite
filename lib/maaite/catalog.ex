defmodule Maaite.Catalog do
  alias Maaite.DuckLake

  defp ensure_meta_attached do
    path = Application.get_env(:maaite, :ducklake_metadata, "priv/ducklake/metadata.sqlite")
    DuckLake.query!("ATTACH IF NOT EXISTS '#{path}' AS meta (TYPE sqlite, READ_ONLY);")
  end

  @doc "Returns aggregate catalog stats."
  def summary do
    ensure_meta_attached()

    sql = """
    SELECT
      COUNT(DISTINCT t.table_id)            AS total_tables,
      SUM(COALESCE(s.record_count, 0))      AS total_records,
      SUM(COALESCE(s.file_size_bytes, 0))   AS total_bytes,
      (SELECT MAX(snapshot_time) FROM meta.ducklake_snapshot) AS latest_snapshot_time
    FROM meta.ducklake_table t
    LEFT JOIN meta.ducklake_table_stats s ON s.table_id = t.table_id
    WHERE t.end_snapshot IS NULL
    """

    case DuckLake.query_maps(sql) do
      [row | _] -> {:ok, row}
      [] -> {:ok, %{"total_tables" => 0, "total_records" => 0, "total_bytes" => 0, "latest_snapshot_time" => nil}}
      {:error, reason} -> {:error, inspect(reason)}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc "Returns one map per table with name, stats, and column count."
  def list_tables do
    ensure_meta_attached()

    sql = """
    SELECT
      t.table_name,
      'main'                               AS schema_name,
      COUNT(c.column_id)                   AS column_count,
      COALESCE(s.record_count, 0)          AS record_count,
      COALESCE(s.file_size_bytes, 0)       AS file_size_bytes,
      (SELECT MAX(snap.snapshot_time) FROM meta.ducklake_snapshot snap
       WHERE snap.snapshot_id = t.begin_snapshot) AS last_snapshot_time
    FROM meta.ducklake_table t
    LEFT JOIN meta.ducklake_column c
      ON c.table_id = t.table_id AND c.end_snapshot IS NULL
    LEFT JOIN meta.ducklake_table_stats s ON s.table_id = t.table_id
    WHERE t.end_snapshot IS NULL
    GROUP BY t.table_name, t.begin_snapshot, s.record_count, s.file_size_bytes
    ORDER BY t.table_name
    """

    case DuckLake.query_maps(sql) do
      {:error, reason} -> {:error, inspect(reason)}
      rows -> {:ok, rows}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc "Returns the last 20 snapshot entries."
  def recent_snapshots do
    ensure_meta_attached()

    sql = """
    SELECT
      snap.snapshot_id,
      snap.snapshot_time,
      COALESCE(chg.changes_made, '') AS changes_made
    FROM meta.ducklake_snapshot snap
    LEFT JOIN meta.ducklake_snapshot_changes chg ON chg.snapshot_id = snap.snapshot_id
    ORDER BY snap.snapshot_time DESC
    LIMIT 20
    """

    case DuckLake.query_maps(sql) do
      {:error, reason} -> {:error, inspect(reason)}
      rows -> {:ok, rows}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  @doc "Returns column definitions for the given table name."
  def columns_for_table(table_name) do
    ensure_meta_attached()

    sql = """
    SELECT c.column_name, c.column_type, c.column_id, c.column_order
    FROM meta.ducklake_column c
    JOIN meta.ducklake_table t ON t.table_id = c.table_id
    WHERE t.table_name = ? AND c.end_snapshot IS NULL AND t.end_snapshot IS NULL
    ORDER BY c.column_order
    """

    case DuckLake.query_maps(sql, [table_name]) do
      {:error, reason} -> {:error, inspect(reason)}
      rows -> {:ok, rows}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  def format_bytes(nil), do: "—"
  def format_bytes(%Decimal{} = n), do: format_bytes(Decimal.to_integer(n))
  def format_bytes(0), do: "0 B"

  def format_bytes(n) when is_integer(n) or is_float(n) do
    cond do
      n >= 1_073_741_824 -> "#{Float.round(n / 1_073_741_824, 1)} GB"
      n >= 1_048_576 -> "#{Float.round(n / 1_048_576, 1)} MB"
      n >= 1_024 -> "#{Float.round(n / 1_024, 1)} KB"
      true -> "#{n} B"
    end
  end

  def format_number(nil), do: "—"
  def format_number(%Decimal{} = n), do: format_number(Decimal.to_integer(n))

  def format_number(n) when is_integer(n) do
    n
    |> Integer.to_string()
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.chunk_every(3)
    |> Enum.map(&Enum.join/1)
    |> Enum.join(",")
    |> String.graphemes()
    |> Enum.reverse()
    |> Enum.join()
  end

  def format_number(n) when is_float(n), do: format_number(round(n))
end
