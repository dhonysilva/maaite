defmodule Maaite.DuckLake do
  require Logger

  @conn Maaite.DuckConn

  @doc """
  Run once at startup to install extensions and attach the DuckLake catalog.
  Safe to call multiple times (ATTACH is idempotent with IF NOT EXISTS).
  """
  def setup! do
    metadata = Application.get_env(:maaite, :ducklake_metadata, "priv/ducklake/metadata.sqlite")
    data_path = Application.get_env(:maaite, :ducklake_data_path, "priv/ducklake/data_files/")

    File.mkdir_p!(Path.dirname((metadata)))
    File.mkdir_p!(data_path)

    statements = [
      "INSTALL ducklake;",
      "INSTALL sqlite;",
      "ATTACH IF NOT EXISTS 'ducklake:sqlite:#{metadata}' AS my_ducklake (DATA_PATH '#{data_path}');",
    ]

    for sql <- statements do
      case Adbc.Connection.query(@conn, sql) do
        {:ok, _} -> :ok
        {:error, reason} -> Logger.warning("DuckLake setup warning: #{inspect(reason)}")
      end
    end

    :ok
  end

  @doc "Run a query against the DuckLake catalog."
  def query!(sql, params \\ []) do
    case Adbc.Connection.query(@conn, sql, params) do
      {:ok, result} -> result
      {:error, reason} -> raise "DuckLake query error: #{inspect(reason)}"
    end
  end

  @doc "Run a query and return rows as a list of maps."
  def query_maps(sql, params \\ []) do
    case Adbc.Connection.query(@conn, sql, params) do
      {:ok, %Adbc.Result{data: columns}} ->
        # ADBC returns columnar data — zip into row maps
        col_names = Enum.map(columns, fn {name, _} -> name end)
        col_values = Enum.map(columns, fn {_, vals} -> vals end)

        col_values
        |> Enum.zip_with(& &1)
        |> Enum.map(fn row ->
          col_names |> Enum.zip(row) |> Map.new()
        end)

      {:error, reason} ->
        {:error, reason}
    end
  end
end
