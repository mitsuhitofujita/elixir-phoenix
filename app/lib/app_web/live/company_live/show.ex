defmodule AppWeb.CompanyLive.Show do
  @moduledoc """
  LiveView responsible for company detail and edit flows.
  """
  use AppWeb, :live_view

  alias App.Companies
  alias AppWeb.CompanyLive.FormComponent

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:company, nil)
     |> assign(:patch, nil)
     |> assign(:page_title, "Company Details")}
  end

  @impl true
  def handle_params(%{"id" => company_id} = params, _url, socket) do
    company = Companies.get_company!(company_id)

    {:noreply,
     socket
     |> assign(:company, company)
     |> assign(:patch, ~p"/companies/#{company}")
     |> apply_action(socket.assigns.live_action, params)}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case Companies.delete_company(socket.assigns.company) do
      {:ok, _result} ->
        {:noreply,
         socket
         |> put_flash(:info, "Company deleted successfully")
         |> push_navigate(to: ~p"/companies")}

      {:error, _failed_operation, _value, _changes_so_far} ->
        {:noreply, put_flash(socket, :error, "Unable to delete the selected company")}
    end
  end

  @impl true
  def handle_info({FormComponent, {:saved, company}}, socket) do
    {:noreply,
     socket
     |> assign(:company, company)
     |> put_flash(:info, "Company updated successfully")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-8">
        <.header>
          {@company.name}
          <:subtitle>
            Code {@company.code} · {if(@company.is_active, do: "Active", else: "Inactive")}
          </:subtitle>
          <:actions>
            <div class="flex flex-wrap gap-3">
              <.link navigate={~p"/companies"} class="btn btn-ghost btn-sm">
                <.icon name="hero-arrow-left" class="size-4" />
                Back to list
              </.link>
              <.link
                navigate={~p"/audit-logs"}
                class="btn btn-ghost btn-sm"
                title="Review past changes in the audit log"
              >
                <.icon name="hero-clock" class="size-4" />
                Audit log
              </.link>
              <.link
                patch={~p"/companies/#{@company.id}/show/edit"}
                class="btn btn-primary btn-sm"
              >
                <.icon name="hero-pencil-square" class="size-4" />
                Edit
              </.link>
              <button
                type="button"
                phx-click="delete"
                data-confirm={"Delete #{@company.name}? The audit trail will capture this deletion."}
                class="btn btn-error btn-sm btn-soft"
              >
                Delete
              </button>
            </div>
          </:actions>
        </.header>

        <div class="grid gap-6 lg:grid-cols-3">
          <div class="card border border-base-300 bg-base-200 p-6 lg:col-span-2">
            <div class="space-y-1 pb-4">
              <p class="text-xs uppercase tracking-wide text-base-content/60">Profile snapshot</p>
              <h2 class="text-xl font-semibold text-base-content">Company overview</h2>
              <p class="text-sm text-base-content/70">
                Every update is wrapped in a transaction with audit logging so this overview always reflects the latest saved record.
              </p>
            </div>
            <dl class="grid gap-4 text-sm md:grid-cols-2">
              <div>
                <dt class="text-base-content/60">Company code</dt>
                <dd class="font-medium text-base-content">{@company.code}</dd>
              </div>
              <div>
                <dt class="text-base-content/60">Capital amount</dt>
                <dd class="font-medium text-base-content">{format_capital(@company.capital_amount)}</dd>
              </div>
              <div>
                <dt class="text-base-content/60">Founded at</dt>
                <dd class="font-medium text-base-content">{format_date(@company.founded_at)}</dd>
              </div>
              <div>
                <dt class="text-base-content/60">Established at</dt>
                <dd class="font-medium text-base-content">{format_date(@company.established_at)}</dd>
              </div>
              <div>
                <dt class="text-base-content/60">Status</dt>
                <dd class="mt-1">
                  <span class={[
                    "badge",
                    @company.is_active && "badge-success badge-soft",
                    !@company.is_active && "badge-outline"
                  ]}>
                    {if(@company.is_active, do: "Active", else: "Inactive")}
                  </span>
                </dd>
              </div>
              <div>
                <dt class="text-base-content/60">Last updated</dt>
                <dd class="font-medium text-base-content">{format_datetime(@company.updated_at)}</dd>
              </div>
              <div>
                <dt class="text-base-content/60">Created at</dt>
                <dd class="font-medium text-base-content">{format_datetime(@company.created_at)}</dd>
              </div>
            </dl>
          </div>
          <div class="card border border-base-300 bg-base-100 p-6 space-y-4">
            <div>
              <p class="text-xs uppercase tracking-wide text-base-content/60">Why it matters</p>
              <h3 class="text-lg font-semibold text-base-content">Audit-ready detail</h3>
              <p class="text-sm text-base-content/70">
                Each save operation stores the full company payload in <.link navigate={~p"/audit-logs"} class="link link-primary">Audit Logs</.link>,
                so you can diff historical values without leaving this workspace.
              </p>
            </div>
            <ul class="space-y-2 text-sm text-base-content/80">
              <li class="flex items-start gap-2">
                <.icon name="hero-check-circle" class="size-4 text-success" />
                Transactional writes keep company changes and audit entries in sync.
              </li>
              <li class="flex items-start gap-2">
                <.icon name="hero-check-circle" class="size-4 text-success" />
                Toggle inactive companies back on from the list view at any time.
              </li>
              <li class="flex items-start gap-2">
                <.icon name="hero-check-circle" class="size-4 text-success" />
                Designers get immediate validation feedback when updating this record.
              </li>
            </ul>
          </div>
        </div>

        <div
          :if={@live_action == :edit}
          class="card border border-base-300 bg-base-100 p-6 shadow-lg"
        >
          <div class="space-y-2 pb-4">
            <p class="text-xs uppercase tracking-wide text-base-content/60">Edit company</p>
            <h2 class="text-xl font-semibold text-base-content">Update company profile</h2>
            <p class="text-sm text-base-content/70">
              Saving pushes a fresh audit entry so downstream reviewers know exactly what changed.
            </p>
          </div>

          <.live_component
            module={FormComponent}
            id="company-show-form-component"
            action={@live_action}
            company={@company}
            patch={@patch}
          />
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp apply_action(socket, :edit, _params) do
    socket
    |> assign(:page_title, "Edit Company")
  end

  defp apply_action(socket, _action, _params) do
    socket
    |> assign(:page_title, "Company Details")
  end

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

  defp format_capital(amount) when is_integer(amount), do: "¥" <> Integer.to_string(amount)
end
