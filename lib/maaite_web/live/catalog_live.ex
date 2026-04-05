defmodule MaaiteWeb.CatalogLive do
  use MaaiteWeb, :live_view

  alias Maaite.Catalog

  @impl true
  def mount(_params, _session, socket) do
    socket =
      try do
        load_data(socket)
      rescue
        e ->
          socket
          |> assign(empty_state())
          |> put_flash(:error, "Failed to load catalog: #{Exception.message(e)}")
      end

    {:ok, socket}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket =
      try do
        load_data(socket)
      rescue
        e -> put_flash(socket, :error, "Refresh failed: #{Exception.message(e)}")
      end

    {:noreply, socket}
  end

  def handle_event("select_table", %{"table" => table_name}, socket) do
    {columns, socket} =
      case Catalog.columns_for_table(table_name) do
        {:ok, rows} -> {rows, socket}
        {:error, reason} -> {[], put_flash(socket, :error, "Columns error: #{reason}")}
      end

    {:noreply, assign(socket, selected_table: table_name, columns: columns)}
  end

  def handle_event("close_drawer", _params, socket) do
    {:noreply, assign(socket, selected_table: nil, columns: [])}
  end

  defp load_data(socket) do
    {summary, socket} =
      case Catalog.summary() do
        {:ok, s} -> {s, socket}
        {:error, reason} -> {nil, put_flash(socket, :error, "Summary error: #{reason}")}
      end

    {tables, socket} =
      case Catalog.list_tables() do
        {:ok, rows} -> {rows, socket}
        {:error, reason} -> {[], put_flash(socket, :error, "Tables error: #{reason}")}
      end

    {snapshots, socket} =
      case Catalog.recent_snapshots() do
        {:ok, rows} -> {rows, socket}
        {:error, reason} -> {[], put_flash(socket, :error, "Snapshots error: #{reason}")}
      end

    assign(socket,
      page_title: "Catalog",
      summary: summary,
      tables: tables,
      snapshots: snapshots,
      selected_table: nil,
      columns: [],
      loading: false
    )
  end

  defp empty_state do
    [
      page_title: "Catalog",
      summary: nil,
      tables: [],
      snapshots: [],
      selected_table: nil,
      columns: [],
      loading: false
    ]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.header>
      DuckLake Catalog
      <:subtitle>Metadata from <code>priv/ducklake/metadata.sqlite</code></:subtitle>
      <:actions>
        <button
          phx-click="refresh"
          class="flex items-center gap-2 rounded-lg bg-zinc-800 px-3 py-2 text-sm font-semibold text-white hover:bg-zinc-700"
        >
          <.icon name="hero-arrow-path" class="h-4 w-4" /> Refresh
        </button>
      </:actions>
    </.header>

    <%!-- Summary stat cards --%>
    <div class="mt-8 grid grid-cols-2 gap-4 sm:grid-cols-4">
      <.stat_card
        icon="hero-table-cells"
        label="Total Tables"
        value={if @summary, do: to_string(@summary["total_tables"] || 0), else: "—"}
      />
      <.stat_card
        icon="hero-circle-stack"
        label="Total Records"
        value={if @summary, do: Catalog.format_number(@summary["total_records"]), else: "—"}
      />
      <.stat_card
        icon="hero-server"
        label="Storage"
        value={if @summary, do: Catalog.format_bytes(@summary["total_bytes"]), else: "—"}
      />
      <.stat_card
        icon="hero-clock"
        label="Latest Snapshot"
        value={format_time(@summary && @summary["latest_snapshot_time"])}
      />
    </div>

    <%!-- Tables section --%>
    <section class="mt-10">
      <h2 class="mb-4 text-lg font-semibold text-zinc-900">Tables</h2>
      <.table
        id="catalog-tables"
        rows={@tables}
        row_click={fn row -> JS.push("select_table", value: %{table: row["table_name"]}) end}
      >
        <:col :let={row} label="Name">
          <span class="font-mono font-medium text-zinc-900">{row["table_name"]}</span>
        </:col>
        <:col :let={row} label="Schema">
          <span class="text-zinc-500">{row["schema_name"]}</span>
        </:col>
        <:col :let={row} label="Columns">
          {row["column_count"]}
        </:col>
        <:col :let={row} label="Records">
          {Catalog.format_number(row["record_count"])}
        </:col>
        <:col :let={row} label="Storage">
          {Catalog.format_bytes(row["file_size_bytes"])}
        </:col>
        <:col :let={row} label="Last Snapshot">
          {format_time(row["last_snapshot_time"])}
        </:col>
      </.table>
    </section>

    <%!-- Snapshot history section --%>
    <section class="mt-10 mb-16">
      <h2 class="mb-4 text-lg font-semibold text-zinc-900">Snapshot History</h2>
      <div class="overflow-hidden rounded-xl border border-zinc-200">
        <div
          :for={snap <- @snapshots}
          class="flex items-center gap-4 border-b border-zinc-100 px-4 py-3 last:border-0 hover:bg-zinc-50"
        >
          <span class="shrink-0 rounded-full bg-zinc-100 px-2 py-0.5 font-mono text-xs text-zinc-600">
            #{snap["snapshot_id"]}
          </span>
          <span class="flex-1 truncate text-sm text-zinc-700">
            {snap["changes_made"]}
          </span>
          <span class="shrink-0 text-xs text-zinc-400">
            {format_time(snap["snapshot_time"])}
          </span>
        </div>
        <div :if={@snapshots == []} class="px-4 py-8 text-center text-sm text-zinc-400">
          No snapshots recorded yet.
        </div>
      </div>
    </section>

    <%!-- Column drawer backdrop --%>
    <div
      :if={@selected_table}
      class="fixed inset-0 z-40 bg-black/30"
      phx-click="close_drawer"
    />

    <%!-- Column drawer panel --%>
    <div
      :if={@selected_table}
      class="fixed right-0 top-0 z-50 flex h-full w-80 flex-col bg-white shadow-2xl"
    >
      <div class="flex items-center justify-between border-b border-zinc-200 px-4 py-4">
        <h3 class="font-semibold text-zinc-900">
          <span class="font-mono">{@selected_table}</span>
        </h3>
        <button
          phx-click="close_drawer"
          class="rounded p-1 text-zinc-400 hover:bg-zinc-100 hover:text-zinc-600"
        >
          <.icon name="hero-x-mark" class="h-5 w-5" />
        </button>
      </div>
      <div class="flex-1 overflow-y-auto px-4 py-4">
        <p class="mb-3 text-xs font-semibold uppercase tracking-wide text-zinc-400">Columns</p>
        <div class="space-y-2">
          <div
            :for={col <- @columns}
            class="flex items-center justify-between rounded-lg bg-zinc-50 px-3 py-2"
          >
            <span class="font-mono text-sm text-zinc-800">{col["column_name"]}</span>
            <span class="rounded bg-brand/10 px-2 py-0.5 font-mono text-xs text-brand">
              {col["column_type"]}
            </span>
          </div>
          <div :if={@columns == []} class="py-4 text-center text-sm text-zinc-400">
            No columns found.
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp stat_card(assigns) do
    ~H"""
    <div class="rounded-xl border border-zinc-200 bg-white p-4">
      <div class="flex items-center gap-2 text-zinc-500">
        <.icon name={@icon} class="h-4 w-4" />
        <span class="text-xs font-medium">{@label}</span>
      </div>
      <p class="mt-2 text-2xl font-bold text-zinc-900">{@value}</p>
    </div>
    """
  end

  defp format_time(nil), do: "—"
  defp format_time(""), do: "—"

  defp format_time(ts) when is_binary(ts) do
    case DateTime.from_iso8601(ts) do
      {:ok, dt, _} -> Calendar.strftime(dt, "%b %d, %Y %H:%M")
      _ -> ts
    end
  end

  defp format_time(ts), do: to_string(ts)

end
