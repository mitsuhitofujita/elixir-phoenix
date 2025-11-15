Mix.Task.run("loadpaths")
Mix.Task.run("app.config")

Application.load(:app)

Enum.each([:logger, :postgrex, :ecto, :app], fn app ->
  {:ok, _} = Application.ensure_all_started(app)
end)

defmodule Scripts.VerifyDatabasesAndSchemas do
  @moduledoc false

  @schema_name "main"

  def run do
    repo_config = Application.fetch_env!(:app, App.Repo)

    connection_opts =
      repo_config
      |> Keyword.take([:hostname, :port, :username, :password, :socket_dir, :ssl, :parameters])

    dev_db = Keyword.fetch!(repo_config, :database)
    test_db = "app_test" <> (System.get_env("MIX_TEST_PARTITION") || "")

    targets = [
      %{label: "Development", database: dev_db, schema: @schema_name},
      %{label: "Test", database: test_db, schema: @schema_name}
    ]

    results =
      Enum.map(targets, fn target ->
        check_database(target, connection_opts)
      end)

    if Enum.all?(results, & &1) do
      IO.puts("\nAll checks passed.")
      System.halt(0)
    else
      IO.puts(:stderr, "\nSome checks failed. See messages above for details.")
      System.halt(1)
    end
  end

  defp check_database(target, base_opts) do
    IO.puts("\n==> Checking #{target.label} database (#{target.database})")

    opts = Keyword.put(base_opts, :database, target.database)

    case Postgrex.start_link(opts) do
      {:ok, pid} ->
        IO.puts("  ✓ Connected as #{opts[:username]} to #{target.database}")

        schema_exists? = schema_exists?(pid, target.database, target.schema)
        GenServer.stop(pid)
        schema_exists?

      {:error, reason} ->
        IO.puts(:stderr, "  ✗ Failed to connect to #{target.database}: #{format_error(reason)}")
        false
    end
  end

  defp schema_exists?(conn, database, schema) do
    query = """
    SELECT 1
    FROM information_schema.schemata
    WHERE schema_name = $1
    """

    case Postgrex.query(conn, query, [schema]) do
      {:ok, %Postgrex.Result{rows: [_ | _]}} ->
        IO.puts("  ✓ Schema \"#{schema}\" exists in #{database}")
        true

      {:ok, _} ->
        IO.puts(:stderr, "  ✗ Schema \"#{schema}\" is missing in #{database}")
        false

      {:error, error} ->
        IO.puts(:stderr, "  ✗ Failed to inspect schemas in #{database}: #{format_error(error)}")
        false
    end
  end

  defp format_error(%{postgres: %{message: message}}), do: String.trim(message)
  defp format_error(%{message: message}), do: String.trim(message)
  defp format_error(other), do: inspect(other)
end

Scripts.VerifyDatabasesAndSchemas.run()
