defmodule App.CompaniesFixtures do
  @moduledoc """
  Helpers for creating company records in tests.
  """

  alias App.Companies

  def unique_company_name do
    "Company #{System.unique_integer([:positive])}"
  end

  def unique_company_code do
    "CC#{System.unique_integer([:positive])}"
  end

  def valid_company_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_company_name(),
      code: unique_company_code(),
      capital_amount: 100_000,
      founded_at: ~D[2010-01-01],
      established_at: ~D[2010-02-01],
      is_active: true
    })
  end

  def company_fixture(attrs \\ %{}) do
    attrs
    |> valid_company_attributes()
    |> Companies.create_company()
    |> case do
      {:ok, %{company: company}} ->
        company

      {:error, :company, changeset, _} ->
        raise "company_fixture/1 failed: #{inspect(changeset.errors)}"
    end
  end
end
