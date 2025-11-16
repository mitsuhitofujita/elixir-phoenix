defmodule App.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :text, null: false
      add :code, :text, null: false
      add :capital_amount, :bigint
      add :founded_at, :date
      add :established_at, :date
      add :is_active, :boolean, null: false, default: true

      timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: :updated_at)
    end

    create unique_index(:companies, [:code],
             where: "is_active = true",
             name: :companies_active_code_index
           )

    create index(:companies, [:is_active])
  end
end
