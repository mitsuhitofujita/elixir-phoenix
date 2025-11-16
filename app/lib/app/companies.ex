defmodule App.Companies do
  @moduledoc """
  Context responsible for company persistence and audit logging.
  """

  import Ecto.Query, warn: false

  alias App.Companies.{AuditLog, Company}
  alias App.Repo
  alias Decimal
  alias Ecto.Multi

  @dialyzer {:no_opaque, delete_company: 1}
  @dialyzer {:no_opaque, persist_with_audit: 2}

  @doc """
  Lists companies, optionally filtered by `:is_active`.

  ## Examples

      iex> App.Companies.list_companies()
      []

      iex> App.Companies.list_companies(is_active: true)
      []
  """
  def list_companies(opts \\ []) do
    Company
    |> maybe_filter_active(opts)
    |> Repo.all()
  end

  @doc """
  Fetches a single company by id.
  """
  def get_company!(id), do: Repo.get!(Company, id)

  @doc """
  Builds a changeset for tracking company updates.
  """
  def change_company(%Company{} = company, attrs \\ %{}) do
    Company.changeset(company, attrs)
  end

  @doc """
  Creates a company and writes a matching audit log entry inside the same transaction.
  """
  def create_company(attrs \\ %{}) do
    %Company{}
    |> Company.changeset(attrs)
    |> persist_with_audit("create")
  end

  @doc """
  Updates a company and writes a matching audit log entry inside the same transaction.
  """
  def update_company(%Company{} = company, attrs) do
    company
    |> Company.changeset(attrs)
    |> persist_with_audit("update")
  end

  @doc """
  Deletes a company and writes a matching audit log entry inside the same transaction.
  """
  def delete_company(%Company{} = company) do
    multi = new_multi()
    multi = Multi.delete(multi, :company, company)
    multi = attach_audit_log(multi, "delete")
    Repo.transaction(multi)
  end

  defp persist_with_audit(%Ecto.Changeset{} = changeset, action) do
    multi = new_multi()
    multi = Multi.insert_or_update(multi, :company, changeset)
    multi = attach_audit_log(multi, action)
    Repo.transaction(multi)
  end

  @spec attach_audit_log(Ecto.Multi.t(), String.t()) :: Ecto.Multi.t()
  defp attach_audit_log(multi, action) do
    Multi.run(multi, :audit_log, fn repo, %{company: company} ->
      attrs = %{
        action: action,
        entity: "company",
        entity_id: company.id,
        changed_data: serialize_company(company)
      }

      repo.insert(AuditLog.changeset(%AuditLog{}, attrs))
    end)
  end

  defp serialize_company(%Company{} = company) do
    company
    |> Map.from_struct()
    |> Map.drop([:__meta__, :__struct__])
    |> Map.new(fn {key, value} ->
      {Atom.to_string(key), serialize_value(value)}
    end)
  end

  defp serialize_value(%Decimal{} = value), do: Decimal.to_string(value, :normal)
  defp serialize_value(%Date{} = value), do: Date.to_iso8601(value)
  defp serialize_value(%NaiveDateTime{} = value), do: NaiveDateTime.to_iso8601(value)
  defp serialize_value(%DateTime{} = value), do: DateTime.to_iso8601(value)
  defp serialize_value(%Time{} = value), do: Time.to_iso8601(value)

  defp serialize_value(%{} = map) do
    Map.new(map, fn {key, value} -> {key, serialize_value(value)} end)
  end

  defp serialize_value(list) when is_list(list) do
    Enum.map(list, &serialize_value/1)
  end

  defp serialize_value(value), do: value

  defp maybe_filter_active(query, opts) do
    case Keyword.fetch(opts, :is_active) do
      {:ok, value} when is_boolean(value) ->
        from c in query, where: c.is_active == ^value

      _ ->
        query
    end
  end

  defp new_multi, do: Multi.new()
end
