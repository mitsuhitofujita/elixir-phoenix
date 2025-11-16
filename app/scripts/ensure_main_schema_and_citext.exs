Mix.Task.run("loadpaths")
Mix.Task.run("app.config")

Application.load(:app)

Enum.each([:logger, :postgrex, :ecto, :app], fn app ->
  {:ok, _} = Application.ensure_all_started(app)
end)

alias App.Repo

defmodule Scripts.EnsureMainSchemaAndCitext do
  @schema "main"
  @extension "citext"

  def run do
    username = Repo.config()[:username] || System.get_env("PGUSER") || "app"
    database = Repo.config()[:database] || "app_dev"

    IO.puts("Ensuring #{@schema} schema and #{@extension} extension exist in #{database}...")

    [
      {"Ensure schema", "CREATE SCHEMA IF NOT EXISTS #{@schema}"},
      {"Grant schema privileges", "GRANT ALL ON SCHEMA #{@schema} TO #{username}"},
      {"Set search_path", "ALTER ROLE #{username} SET search_path = #{@schema}, public"},
      {"Grant default table privileges",
       "ALTER DEFAULT PRIVILEGES FOR USER #{username} IN SCHEMA #{@schema} GRANT ALL ON TABLES TO #{username}"},
      {"Grant default sequence privileges",
       "ALTER DEFAULT PRIVILEGES FOR USER #{username} IN SCHEMA #{@schema} GRANT ALL ON SEQUENCES TO #{username}"},
      {"Ensure citext extension", "CREATE EXTENSION IF NOT EXISTS #{@extension} SCHEMA #{@schema}"}
    ]
    |> Enum.each(&execute/1)

    IO.puts("Setup complete.")
  end

  defp execute({label, sql}) do
    case Repo.query(sql) do
      {:ok, _result} ->
        IO.puts("  ✔ #{label}")

      {:error, %Postgrex.Error{} = error} ->
        IO.puts(:stderr, "  ✖ #{label} failed: #{error.postgres.message}")
        System.halt(1)

      {:error, error} ->
        IO.puts(:stderr, "  ✖ #{label} failed: #{inspect(error)}")
        System.halt(1)
    end
  end
end

Scripts.EnsureMainSchemaAndCitext.run()
