defmodule AppWeb.CompanyLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.CompaniesFixtures

  alias App.Companies.{AuditLog, Company}
  alias App.Repo

  describe "Index" do
    setup [:register_and_log_in_user]

    test "renders active companies by default and toggles the is_active filter", %{conn: conn} do
      active_company = company_fixture(%{name: "Active Corp"})
      inactive_company = company_fixture(%{name: "Inactive Corp", is_active: false})

      {:ok, view, html} = live(conn, ~p"/companies")

      assert html =~ "Company Directory"
      assert html =~ active_company.name
      refute html =~ inactive_company.name
      assert has_element?(view, "a[href=\"#{~p"/audit-logs"}\"]", "Audit log")

      view
      |> element("a[href=\"#{~p"/companies?filter=all"}\"]")
      |> render_click()

      assert_patch(view, ~p"/companies?filter=all")

      html = render(view)
      assert html =~ active_company.name
      assert html =~ inactive_company.name
    end

    test "creates a company after validation feedback", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/companies")

      assert view |> element("#new-company") |> render_click() =~ "Add a new organization"
      assert_patch(view, ~p"/companies/new?filter=active")

      assert view
             |> form("#company-form", company: %{name: "", code: "", is_active: true})
             |> render_change() =~ "can&#39;t be blank"

      attrs = valid_company_attributes(%{name: "New Org"})

      view
      |> form("#company-form", company: attrs)
      |> render_submit()

      assert_patch(view, ~p"/companies?filter=active")

      html = render(view)
      assert html =~ "Company created successfully"
      assert html =~ attrs[:name]
    end

    test "updates a company inline from the list", %{conn: conn} do
      company = company_fixture(%{name: "Before Rename"})

      {:ok, view, _} = live(conn, ~p"/companies")

      view
      |> element("a[href=\"#{~p"/companies/#{company.id}/edit?filter=active"}\"]", "Edit")
      |> render_click()

      assert_patch(view, ~p"/companies/#{company.id}/edit?filter=active")

      params = company_form_params(company, %{name: "After Rename"})

      view
      |> form("#company-form", company: params)
      |> render_submit()

      assert_patch(view, ~p"/companies?filter=active")

      html = render(view)
      assert html =~ "Company updated successfully"
      assert html =~ "After Rename"
    end

    test "deletes a company from the table", %{conn: conn} do
      company = company_fixture()

      {:ok, view, _} = live(conn, ~p"/companies")

      view
      |> element("button[phx-value-id=\"#{company.id}\"]", "Delete")
      |> render_click()

      html = render(view)
      assert html =~ "Company deleted successfully"
      refute html =~ company.name
    end

    test "navigates to the company details page from the list", %{conn: conn} do
      company = company_fixture()

      {:ok, view, _} = live(conn, ~p"/companies")

      result =
        view
        |> element("a[href=\"#{~p"/companies/#{company.id}"}\"]", "Details")
        |> render_click()

      {:ok, _show_live, html} = follow_redirect(result, conn, ~p"/companies/#{company.id}")
      assert html =~ company.name
    end

    test "does not insert audit logs for invalid submissions", %{conn: conn} do
      existing = company_fixture()
      before_count = Repo.aggregate(AuditLog, :count, :id)

      {:ok, view, _} = live(conn, ~p"/companies")

      view |> element("#new-company") |> render_click()
      assert_patch(view, ~p"/companies/new?filter=active")

      attrs = valid_company_attributes(%{code: existing.code})

      assert view
             |> form("#company-form", company: attrs)
             |> render_submit() =~ "has already been taken"

      assert Repo.aggregate(AuditLog, :count, :id) == before_count
    end

    test "links to the audit log placeholder", %{conn: conn} do
      company_fixture()

      {:ok, view, _} = live(conn, ~p"/companies")

      audit_link_selector = ~s|a[data-phx-link="redirect"][href="#{~p"/audit-logs"}"]|

      result =
        view
        |> element(audit_link_selector, "Audit log")
        |> render_click()

      {:ok, _placeholder, html} = follow_redirect(result, conn, ~p"/audit-logs")

      assert html =~ "Audit Logs"
    end
  end

  describe "Show" do
    setup [:register_and_log_in_user]

    test "renders company detail view", %{conn: conn} do
      company = company_fixture()

      {:ok, view, html} = live(conn, ~p"/companies/#{company}")

      assert html =~ company.name
      assert html =~ company.code
      assert has_element?(view, "a[href=\"#{~p"/audit-logs"}\"]", "Audit log")
    end

    test "updates a company from the detail screen", %{conn: conn} do
      company = company_fixture(%{name: "Detail Original"})

      {:ok, view, _html} = live(conn, ~p"/companies/#{company}")

      view
      |> element("a[href=\"#{~p"/companies/#{company.id}/show/edit"}\"]", "Edit")
      |> render_click()

      assert_patch(view, ~p"/companies/#{company.id}/show/edit")

      params = company_form_params(company, %{name: "Detail Updated"})

      view
      |> form("#company-form", company: params)
      |> render_submit()

      assert_patch(view, ~p"/companies/#{company.id}")

      html = render(view)
      assert html =~ "Company updated successfully"
      assert html =~ "Detail Updated"
    end

    test "deletes a company and redirects back to the list", %{conn: conn} do
      company = company_fixture()

      {:ok, view, _html} = live(conn, ~p"/companies/#{company}")

      result =
        view
        |> element("button[phx-click=\"delete\"]", "Delete")
        |> render_click()

      {:ok, _index_live, html} = follow_redirect(result, conn, ~p"/companies")

      assert html =~ "Company deleted successfully"
      refute html =~ company.name
    end
  end

  describe "Audit log placeholder" do
    setup [:register_and_log_in_user]

    test "renders without errors for authenticated users", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/audit-logs")

      assert html =~ "Audit Logs"
      assert html =~ "This stub confirms"
    end
  end

  defp company_form_params(%Company{} = company, overrides) do
    company
    |> Map.take([:name, :code, :capital_amount, :founded_at, :established_at, :is_active])
    |> Map.merge(overrides)
  end
end
