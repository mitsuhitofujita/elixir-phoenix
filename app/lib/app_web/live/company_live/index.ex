defmodule AppWeb.CompanyLive.Index do
  @moduledoc """
  LiveView powering the Companies index/new/edit flows.
  """
  use AppWeb, :live_view

  alias App.Companies
  alias App.Companies.Company
  alias AppWeb.CompanyLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:companies, [])
     |> assign(:filter, :active)
     |> assign(:company, nil)
     |> assign(:page_title, "Company Directory")
     |> assign(:patch, filter_patch(:active))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    filter = parse_filter(params)

    {:noreply,
     socket
     |> assign(:filter, filter)
     |> assign(:companies, load_companies(filter))
     |> assign(:patch, filter_patch(filter))
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", %{"id" => company_id}, socket) do
    company = Companies.get_company!(company_id)

    case Companies.delete_company(company) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company deleted successfully")
         |> assign(:companies, load_companies(socket.assigns.filter))}

      {:error, _failed_operation, _value, _changes_so_far} ->
        {:noreply, put_flash(socket, :error, "Unable to delete the selected company")}
    end
  end

  @impl true
  def handle_info({FormComponent, {:saved, _company}}, socket) do
    {:noreply, assign(socket, :companies, load_companies(socket.assigns.filter))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-8">
        <.header>
          Company Directory
          <:subtitle>
            Track every company in the attendance platform, toggle between active and archived records,
            and jump straight into the audit log when you need historical context.
          </:subtitle>
          <:actions>
            <div class="flex flex-wrap gap-3">
              <.link navigate={~p"/audit-logs"} class="btn btn-ghost">
                <.icon name="hero-clock" class="size-5" />
                Audit log
              </.link>
              <.link
                patch={~p"/companies/new?filter=#{@filter}"}
                class="btn btn-primary"
                id="new-company"
              >
                <.icon name="hero-plus" class="size-5" />
                New company
              </.link>
            </div>
          </:actions>
        </.header>

        <div class="card border border-base-300 bg-base-200 p-6 space-y-6 shadow-sm">
          <div class="flex flex-col items-start justify-between gap-4 sm:flex-row sm:items-center">
            <div>
              <p class="text-base font-semibold text-base-content">
                {filter_title(@filter)}
              </p>
              <p class="text-sm text-base-content/70">
                {filter_caption(@filter)}
              </p>
            </div>
            <div class="join">
              <.link
                patch={~p"/companies?filter=active"}
                class={[
                  "btn join-item btn-sm",
                  @filter == :active && "btn-primary",
                  @filter != :active && "btn-soft"
                ]}
              >
                Active only
              </.link>
              <.link
                patch={~p"/companies?filter=all"}
                class={[
                  "btn join-item btn-sm",
                  @filter == :all && "btn-primary",
                  @filter != :all && "btn-soft"
                ]}
              >
                All records
              </.link>
            </div>
          </div>

          <div :if={Enum.empty?(@companies)} class="rounded-xl border border-dashed border-base-300 p-8 text-center">
            <p class="font-semibold text-base-content">No companies yet</p>
            <p class="text-sm text-base-content/70">
              Start by creating your first company profile so team members can track attendance correctly.
            </p>
          </div>

          <div :if={not Enum.empty?(@companies)} class="overflow-x-auto">
            <.table id="companies" rows={@companies}>
              <:col :let={company} label="Company">
                <div class="space-y-1">
                  <p class="font-semibold text-base-content">{company.name}</p>
                  <p class="text-sm text-base-content/70">Code · {company.code}</p>
                </div>
              </:col>
              <:col :let={company} label="Founded / Established">
                <div class="space-y-1 text-sm text-base-content/80">
                  <p>Founded: {format_date(company.founded_at)}</p>
                  <p>Established: {format_date(company.established_at)}</p>
                </div>
              </:col>
              <:col :let={company} label="Capital">
                <span class="text-sm font-medium text-base-content">{format_capital(company.capital_amount)}</span>
              </:col>
              <:col :let={company} label="Status">
                <span class={[
                  "badge",
                  company.is_active && "badge-success badge-soft",
                  !company.is_active && "badge-outline"
                ]}>
                  {if(company.is_active, do: "Active", else: "Inactive")}
                </span>
              </:col>
              <:col :let={company} label="Updated at">
                <span class="text-sm text-base-content/70">{format_datetime(company.updated_at)}</span>
              </:col>
              <:action :let={company}>
                <.link navigate={~p"/companies/#{company.id}"} class="link link-primary text-sm">
                  Details
                </.link>
                <.link
                  patch={~p"/companies/#{company.id}/edit?filter=#{@filter}"}
                  class="link text-sm"
                >
                  Edit
                </.link>
                <button
                  type="button"
                  phx-click="delete"
                  phx-value-id={company.id}
                  data-confirm={"Delete #{company.name}? The related audit log will record this action."}
                  class="link text-error text-sm"
                >
                  Delete
                </button>
              </:action>
            </.table>
          </div>
        </div>

        <div
          :if={@live_action in [:new, :edit]}
          class="card border border-base-300 bg-base-100 p-6 shadow-lg"
        >
          <div class="space-y-2 pb-4">
            <p class="text-xs uppercase tracking-wide text-base-content/60">
              {if @live_action == :new, do: "Create company", else: "Edit company"}
            </p>
            <h2 class="text-xl font-semibold text-base-content">
              {if @live_action == :new, do: "Add a new organization", else: "Update company profile"}
            </h2>
            <p class="text-sm text-base-content/70">
              The entire record is stored in the audit log after every change, enabling precise history in the Audit Log screen.
            </p>
          </div>

          <.live_component
            module={FormComponent}
            id="company-form-component"
            action={@live_action}
            company={@company}
            patch={@patch}
          />
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Create Company")
    |> assign(:company, %Company{})
  end

  defp apply_action(socket, :edit, %{"id" => company_id}) do
    socket
    |> assign(:page_title, "Edit Company")
    |> assign(:company, Companies.get_company!(company_id))
  end

  defp apply_action(socket, _action, _params) do
    socket
    |> assign(:page_title, "Company Directory")
    |> assign(:company, nil)
  end

  defp parse_filter(%{"filter" => "all"}), do: :all
  defp parse_filter(_params), do: :active

  defp load_companies(:active), do: Companies.list_companies(is_active: true)
  defp load_companies(:all), do: Companies.list_companies()

  defp filter_title(:active), do: "Active companies"
  defp filter_title(:all), do: "All registered companies"

  defp filter_caption(:active),
    do: "Only active companies are shown to simplify day-to-day attendance work."

  defp filter_caption(:all),
    do: "Includes inactive companies so you can audit or re-enable archived records."

  defp format_date(nil), do: "—"

  defp format_date(%Date{} = date) do
    Calendar.strftime(date, "%Y-%m-%d")
  end

  defp format_datetime(nil), do: "—"

  defp format_datetime(%NaiveDateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  end

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%Y-%m-%d %H:%M")
  end

  defp format_capital(nil), do: "Not provided"

  defp format_capital(capital) when is_integer(capital), do: "¥" <> Integer.to_string(capital)

  defp filter_patch(filter), do: ~p"/companies?filter=#{filter}"
end
