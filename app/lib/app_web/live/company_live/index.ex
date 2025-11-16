defmodule AppWeb.CompanyLive.Index do
  @moduledoc """
  Placeholder LiveView for the Companies CRUD index/new/edit flows.

  Task 04 will flesh out the full CRUD UI; for now this module simply
  verifies that the router and navigation entries resolve correctly.
  """
  use AppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:company_id, Map.get(params, "id"))
     |> assign(:scope_filter, Map.get(params, "filter", "active"))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-6">
        <header class="space-y-1">
          <p class="text-xs uppercase tracking-wide text-base-content/60">Companies</p>
          <h1 class="text-2xl font-semibold text-base-content">{@page_title}</h1>
          <p class="text-sm text-base-content/70">
            The full CRUD interface will ship in Task 04; this placeholder confirms routing for {@scope_filter} scope and any company specific actions.
          </p>
        </header>
        <div class="card border border-base-300 bg-base-200 p-6">
          <p class="text-sm text-base-content/80">
            Active action: <span class="font-semibold">{@live_action}</span>
            <br /> Target company id: {if @company_id, do: @company_id, else: "n/a"}
          </p>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp page_title(:new), do: "Create Company"
  defp page_title(:edit), do: "Edit Company"
  defp page_title(_action), do: "Company Directory"
end
