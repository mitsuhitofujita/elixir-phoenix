defmodule App.Companies.AuditLog do
  @moduledoc """
  Schema describing entity change tracking information.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @valid_actions ~w(create update delete)
  @required_fields ~w(action entity entity_id changed_data)a
  @optional_fields ~w(user_id)a

  schema "audit_logs" do
    field :user_id, :id
    field :action, :string
    field :entity, :string
    field :entity_id, :integer
    field :changed_data, :map

    timestamps(type: :utc_datetime, inserted_at: :created_at, updated_at: false)
  end

  @doc """
  Builds a changeset for audit log persistence.

  ## Examples

      iex> attrs = %{action: "create", entity: "company", entity_id: 1, changed_data: %{"name" => "ACME"}}
      iex> change = App.Companies.AuditLog.changeset(%App.Companies.AuditLog{}, attrs)
      iex> change.valid?
      true
  """
  def changeset(audit_log, attrs) do
    audit_log
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:action, @valid_actions)
  end
end
