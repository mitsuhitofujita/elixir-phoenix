defmodule App.Repo.Migrations.CreateAuditLogs do
  use Ecto.Migration

  def change do
    create table(:audit_logs) do
      add :user_id, references(:users, on_delete: :nothing)
      add :action, :text, null: false
      add :entity, :text, null: false
      add :entity_id, :integer, null: false
      add :changed_data, :map, null: false

      timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: false)
    end

    create index(:audit_logs, [:entity, :entity_id])
  end
end
