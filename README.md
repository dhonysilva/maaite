# Maaite

Embedded analytics platform for building dashboards utilizing the Elixir, Phoenix, LiveView and Livebook technologies.

## Disclaimer

This is an ongoing projet. I am creating this document to keep track of the development process and to share the knowledge with the community. All the informations here are subject to change.

## References

Please, check the following references to understand the context of this project.

* [marimo](https://marimo.io)

*[Provide more explanation about it, and their characteristics]*.

* [Observable Framework](https://observablehq.com/platform/framework)

From the same creator of [d3js](https://d3js.org) JavaScript library for data visualization, the Obserable Framework [more].

* Metabase [Embedded Analytics](https://www.metabase.com/product/embedded-analytics)

*[Provide more explanation about it, and their characteristics]*.


## Objectives

The aim of this project is to create a platform for building analytical dashboards such as the references prior mentioned utilizing the Elixir, Phoenix, LiveView and Livebook technologies. The purpose is to bring the power of Elixir to the data visualization world.

It will be a platform to build analytics dashboards as dynamic web pages, utilizing the Livebook engine to create the visualizations, but instead of an interactive document, it will generate web pages with several charts, tables, and texts.

The users will build different graphics elements and pin them to appear on the central page. When appearing on the central page, it will be possible to resize them and insert text blocks, titles, and other annotations using Markdown.

They will rely on heavy utilization of SQL queries to fetch data from the database and create the indicators that will feed the visualizations. These SQL statements will be placed inside the markdown blocks.

Taking the Observable Framework as an example, loading an external data source

```yaml
---
sql:
  quakes: https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_day.csv
---
```

And then using the SQL to fetch the data:

```sql
SELECT * FROM gaia ORDER BY phot_g_mean_mag LIMIT 10
```

It will imedialety render the data in a table or any other kind of graphic available.

See more examples on the [Observable Framework](https://observablehq.com/framework/sql) documentation.

*[provide some more examples that expalins the use of SQL in the platform and why this is important]*

## Who will utilize this platform?

This is a tool for data analysts, business intelligent developers and data scientists to create dashboards and reports.

This public takes advantage of the features such as window functions, CTEs, and other advanced SQL features to create their indicators.

## Knwon limitations

At this point we don't have Livebook as a mix depedency. It could be something like:


```elixir
defp deps do
  [
    {:livebook, "~> 0.1.0"}
  ]
end
```

It demands more research to understand how to transoform the Livebook as a `mix deps`. Meanwhile, we will use the Livebook as the standalone application.

## Database support

DuckDB, SQLite, BigQuery, Parquet Delta Lake, and others.

During the development, we will learn more about [DuckDB Wasm](https://github.com/duckdb/duckdb-wasm) and about its user cases.

## Running the project

To start your Phoenix server:

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
