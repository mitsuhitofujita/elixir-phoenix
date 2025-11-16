defmodule AppWeb.CompanyLive.Show do
  @moduledoc """
  Placeholder LiveView for company detail flows until the CRUD UI is implemented.
  """
  use AppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, page_title(socket.assigns.live_action))}
  end

  @impl true
  def handle_params(%{"id" => company_id}, _url, socket) do
    {:noreply,
     socket
     |> assign(:company_id, company_id)
     |> assign(:page_title, page_title(socket.assigns.live_action))}
  end

  def handle_params(_params, _url, socket) do
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-4">
        <p class="text-xs uppercase tracking-wide text-base-content/60">Company detail</p>
        <h1 class="text-2xl font-semibold text-base-content">{@page_title}</h1>
        <div class="card border border-base-300 bg-base-200 p-6 space-y-3">
          <p class="text-sm text-base-content/80">
            Showing placeholder content for company <span class="font-semibold">{@company_id || "(unknown)"}</span>.
          </p>
          <p class="text-sm text-base-content/70">
            These routes are wired so future tasks can focus on rendering the actual company summary and audit hooks.
          </p>
        </div>
      </section>
    </Layouts.app>
    """
  end

  defp page_title(:edit), do: "Edit Company"
  defp page_title(_), do: "Company Details"
end
