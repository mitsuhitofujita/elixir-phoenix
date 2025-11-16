defmodule App.Companies.Company do
  @moduledoc """
  Schema describing a company record.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(name code is_active)a
  @optional_fields ~w(capital_amount founded_at established_at)a

  schema "companies" do
    field :name, :string
    field :code, :string
    field :capital_amount, :integer
    field :founded_at, :date
    field :established_at, :date
    field :is_active, :boolean, default: true

    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: :updated_at)
  end

  @doc """
  Builds a changeset for company persistence.

  ## Examples

      iex> change = App.Companies.Company.changeset(%App.Companies.Company{}, %{name: "ACME", code: "AC01"})
      iex> change.valid?
      true
  """
  def changeset(company, attrs) do
    company
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:code, name: :companies_active_code_index)
  end
end
