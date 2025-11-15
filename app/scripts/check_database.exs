Mix.Task.run("loadpaths")
Mix.Task.run("app.config")

Application.load(:app)

{:ok, _} = Application.ensure_all_started(:logger)
{:ok, _} = Application.ensure_all_started(:ecto)
{:ok, _} = Application.ensure_all_started(:app)

alias App.Repo

query = "select current_database(), current_user"

case Repo.query(query) do
  {:ok, %Postgrex.Result{rows: [[database, user]]}} ->
    IO.puts("Successfully connected to #{database} as #{user}.")
    System.halt(0)

  {:ok, _result} ->
    IO.puts("Connected, but unexpected response from the database.")
    System.halt(0)

  {:error, error} ->
    IO.puts(:stderr, """
    Failed to connect to the database:
    #{inspect(error)}
    """)

    System.halt(1)
end
