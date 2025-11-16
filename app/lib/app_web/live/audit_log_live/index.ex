defmodule AppWeb.AuditLogLive.Index do
  @moduledoc """
  Placeholder LiveView for the audit log listing page.
  """
  use AppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Audit Logs")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section class="space-y-4">
        <p class="text-xs uppercase tracking-wide text-base-content/60">History</p>
        <h1 class="text-2xl font-semibold text-base-content">{@page_title}</h1>
        <p class="text-sm text-base-content/70">
          This stub confirms that navigation and routing are ready so later tasks can focus on rendering audit log data.
        </p>
      </section>
    </Layouts.app>
    """
  end
end
