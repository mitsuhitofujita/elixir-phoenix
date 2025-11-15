defmodule App.Repo.Migrations.CreateUsersAuthTables do
  use Ecto.Migration

  @schema_prefix "main"

  def change do
    create table(:users, prefix: @schema_prefix) do
      add :email, :citext, null: false
      add :hashed_password, :string
      add :confirmed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email], prefix: @schema_prefix)

    create table(:users_tokens, prefix: @schema_prefix) do
      add :user_id, references(:users, on_delete: :delete_all, prefix: @schema_prefix), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      add :authenticated_at, :utc_datetime

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create index(:users_tokens, [:user_id], prefix: @schema_prefix)
    create unique_index(:users_tokens, [:context, :token], prefix: @schema_prefix)
  end
end
