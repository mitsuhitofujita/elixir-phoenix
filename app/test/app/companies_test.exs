defmodule App.CompaniesTest do
  use App.DataCase

  alias App.Companies
  alias App.Companies.{AuditLog, Company}
  alias App.Repo

  import App.CompaniesFixtures

  describe "list_companies/1" do
    test "returns all companies when no filter is provided" do
      company = company_fixture()
      assert Companies.list_companies() == [company]
    end

    test "filters companies by is_active flag" do
      active_company = company_fixture()
      inactive_company = company_fixture(%{is_active: false})

      assert Companies.list_companies(is_active: true) == [active_company]
      assert Companies.list_companies(is_active: false) == [inactive_company]
    end
  end

  describe "get_company!/1" do
    test "fetches the company by id" do
      company = company_fixture()
      id = company.id
      assert %Company{id: ^id} = Companies.get_company!(id)
    end
  end

  describe "change_company/2" do
    test "returns a changeset" do
      company = company_fixture()
      assert %Ecto.Changeset{} = Companies.change_company(company)
    end
  end

  describe "create_company/1" do
    test "creates a company and audit log" do
      attrs = valid_company_attributes()

      assert {:ok, %{company: %Company{} = company, audit_log: %AuditLog{} = audit_log}} =
               Companies.create_company(attrs)

      assert audit_log.action == "create"
      assert audit_log.entity == "company"
      assert audit_log.entity_id == company.id
      assert audit_log.changed_data["id"] == company.id
      assert audit_log.changed_data["name"] == company.name
    end

    test "returns error changeset without audit logs" do
      assert {:error, :company, %Ecto.Changeset{} = changeset, _} =
               Companies.create_company(%{name: "Missing code"})

      refute changeset.valid?
      assert Repo.aggregate(AuditLog, :count, :id) == 0
    end

    test "allows duplicate names across companies" do
      company = company_fixture()

      assert {:ok, %{company: %Company{} = new_company}} =
               valid_company_attributes(%{name: company.name})
               |> Companies.create_company()

      assert new_company.name == company.name
      refute new_company.id == company.id
    end

    test "enforces code uniqueness only for active companies" do
      company = company_fixture()

      assert {:error, :company, changeset, _} =
               valid_company_attributes(%{code: company.code})
               |> Companies.create_company()

      assert "has already been taken" in errors_on(changeset).code
    end

    test "allows duplicate codes when new company is inactive" do
      company = company_fixture()

      assert {:ok, %{company: %Company{} = inactive}} =
               valid_company_attributes(%{code: company.code, is_active: false})
               |> Companies.create_company()

      refute inactive.id == company.id
      refute inactive.is_active
    end

    test "serializes complex types for audit logs" do
      attrs =
        valid_company_attributes(%{
          capital_amount: 12_345,
          founded_at: ~D[2022-01-02],
          established_at: ~D[2022-03-04]
        })

      assert {:ok, %{audit_log: %AuditLog{} = audit_log}} = Companies.create_company(attrs)

      assert audit_log.changed_data["capital_amount"] == 12_345
      assert audit_log.changed_data["founded_at"] == "2022-01-02"
      assert audit_log.changed_data["established_at"] == "2022-03-04"
      assert is_binary(audit_log.changed_data["created_at"])
      assert is_binary(audit_log.changed_data["updated_at"])
    end
  end

  describe "update_company/2" do
    test "updates the company and writes audit logs" do
      company = company_fixture()
      Repo.delete_all(AuditLog)

      assert {:ok, %{company: %Company{} = updated, audit_log: %AuditLog{} = audit_log}} =
               Companies.update_company(company, %{name: "Updated Name"})

      assert updated.name == "Updated Name"
      assert audit_log.action == "update"
      assert audit_log.changed_data["name"] == "Updated Name"
    end

    test "returns error changeset and does not create audit logs" do
      company = company_fixture()
      Repo.delete_all(AuditLog)

      assert {:error, :company, %Ecto.Changeset{}, _} =
               Companies.update_company(company, %{name: nil})

      assert Repo.aggregate(AuditLog, :count, :id) == 0
    end
  end

  describe "delete_company/1" do
    test "deletes the company and writes audit logs" do
      company = company_fixture()
      Repo.delete_all(AuditLog)

      assert {:ok, %{company: %Company{}, audit_log: %AuditLog{} = audit_log}} =
               Companies.delete_company(company)

      assert audit_log.action == "delete"
      assert audit_log.changed_data["id"] == company.id

      assert_raise Ecto.NoResultsError, fn ->
        Companies.get_company!(company.id)
      end
    end
  end
end
