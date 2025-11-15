Mix.Task.run("loadpaths")
Mix.Task.run("app.config")

Application.load(:app)

Enum.each([:logger, :postgrex, :ecto, :app], fn app ->
  {:ok, _} = Application.ensure_all_started(app)
end)

alias App.Repo

columns_query = """
SELECT table_schema,
       table_name,
       column_name,
       data_type,
       is_nullable,
       column_default
FROM information_schema.columns
WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
ORDER BY table_schema, table_name, ordinal_position
"""

case Repo.query(columns_query) do
  {:ok, %Postgrex.Result{rows: []}} ->
    IO.puts("No user-defined tables were found in the connected database.")

  {:ok, %Postgrex.Result{rows: rows}} ->
    rows
    |> Enum.group_by(fn [schema, table | _] -> {schema, table} end)
    |> Enum.sort_by(fn {{schema, table}, _} -> {schema, table} end)
    |> Enum.with_index(1)
    |> Enum.each(fn {{{schema, table}, columns}, index} ->
      IO.puts("\n#{index}. #{schema}.#{table}")

      columns
      |> Enum.map(fn [_, _, column, data_type, is_nullable, default] ->
        null_text = if is_nullable == "NO", do: " NOT NULL", else: ""
        default_text = if is_nil(default), do: "", else: " DEFAULT #{default}"
        "  • #{column}: #{data_type}#{null_text}#{default_text}"
      end)
      |> Enum.each(&IO.puts/1)
    end)

    IO.puts("\nFound #{rows |> Enum.map(fn [schema, table | _] -> {schema, table} end) |> Enum.uniq() |> length()} tables.")

  {:error, error} ->
    IO.puts(:stderr, "Failed to inspect tables: #{inspect(error)}")
    System.halt(1)
end
