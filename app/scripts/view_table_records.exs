Mix.Task.run("loadpaths")
Mix.Task.run("app.config")

Application.load(:app)

Enum.each([:logger, :postgrex, :ecto, :app], fn app ->
  {:ok, _} = Application.ensure_all_started(app)
end)

defmodule Scripts.ViewTableRecords do
  alias App.Repo

  @default_schema "main"

  def run(opts) do
    case opts[:table] do
      nil ->
        list_available_tables()

      table_opt ->
        {schema, table} = resolve_schema_and_table(table_opt, opts[:schema])
        fetch_and_print_rows(schema, table)
    end
  end

  defp resolve_schema_and_table(table_opt, explicit_schema) do
    case String.split(table_opt, ".", parts: 2) do
      [schema, table] ->
        {normalize_identifier!(schema), normalize_identifier!(table)}

      [table] ->
        schema = normalize_identifier!(explicit_schema || @default_schema)
        {schema, normalize_identifier!(table)}
    end
  end

  defp normalize_identifier!(identifier) do
    identifier = String.trim(identifier || "")

    if identifier =~ ~r/^[a-zA-Z_][a-zA-Z0-9_]*$/ do
      identifier
    else
      IO.puts(:stderr, "Invalid identifier: #{identifier}")
      System.halt(1)
    end
  end

  defp list_available_tables do
    query = """
    SELECT table_schema, table_name
    FROM information_schema.tables
    WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
    ORDER BY table_schema, table_name
    """

    case Repo.query(query) do
      {:ok, %Postgrex.Result{rows: []}} ->
        IO.puts("No user-defined tables were found.")

      {:ok, %Postgrex.Result{rows: rows}} ->
        IO.puts("Available tables (use --table or -t to inspect records):")

        rows
        |> Enum.with_index(1)
        |> Enum.each(fn {[schema, table], idx} ->
          IO.puts("#{idx}. #{schema}.#{table}")
        end)

        IO.puts("\nExample: mix run scripts/view_table_records.exs -- --table users")

      {:error, error} ->
        IO.puts(:stderr, "Failed to list tables: #{inspect(error)}")
        System.halt(1)
    end
  end

  defp fetch_and_print_rows(schema, table) do
    query = "SELECT * FROM #{quote_ident(schema)}.#{quote_ident(table)}"

    case Repo.query(query) do
      {:ok, %Postgrex.Result{rows: rows, columns: columns}} ->
        IO.puts("Records from #{schema}.#{table} (#{length(rows)} rows):")
        print_table(columns, rows)

      {:error, %Postgrex.Error{} = error} ->
        IO.puts(:stderr, "Failed to fetch records for #{schema}.#{table}: #{error.postgres.message}")
        System.halt(1)

      {:error, error} ->
        IO.puts(:stderr, "Failed to fetch records for #{schema}.#{table}: #{inspect(error)}")
        System.halt(1)
    end
  end

  defp quote_ident(identifier),
    do: ~s("#{String.replace(identifier, "\"", "\"\"")}")

  defp print_table(_columns, []), do: IO.puts("  (no records found)")

  defp print_table(columns, rows) do
    header = Enum.join(columns, " | ")
    IO.puts(header)
    IO.puts(String.duplicate("-", String.length(header)))

    rows
    |> Enum.each(fn row ->
      row
      |> Enum.map(&format_value/1)
      |> Enum.join(" | ")
      |> IO.puts()
    end)
  end

  defp format_value(%Date{} = date), do: Date.to_iso8601(date)
  defp format_value(%NaiveDateTime{} = dt), do: NaiveDateTime.to_iso8601(dt)
  defp format_value(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp format_value(other), do: inspect(other)
end

args =
  case System.argv() do
    ["--" | rest] -> rest
    other -> other
  end

{opts, _, _} =
  OptionParser.parse(args,
    switches: [table: :string, schema: :string],
    aliases: [t: :table, s: :schema]
  )

Scripts.ViewTableRecords.run(opts)
