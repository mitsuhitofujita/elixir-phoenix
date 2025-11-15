ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(App.Repo, :manual)

Code.require_file("support/conn_case.ex", __DIR__)
Code.require_file("support/data_case.ex", __DIR__)
