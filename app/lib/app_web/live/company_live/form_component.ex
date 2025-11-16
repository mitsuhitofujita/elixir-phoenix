defmodule AppWeb.CompanyLive.FormComponent do
  @moduledoc """
  Live component responsible for handling company create/update forms.
  """
  use AppWeb, :live_component

  alias App.Companies
  alias App.Companies.Company

  @impl true
  def update(%{company: %Company{} = company} = assigns, socket) do
    changeset = Companies.change_company(company)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="space-y-4">
      <.form
        :let={f}
        id="company-form"
        for={@form}
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-4"
      >
        <div class="grid gap-4 md:grid-cols-2">
          <.input field={f[:name]} label="Name" />
          <.input field={f[:code]} label="Code" />
          <.input
            field={f[:capital_amount]}
            label="Capital amount (JPY)"
            type="number"
            step="1"
            min="0"
            inputmode="numeric"
          />
          <.input field={f[:is_active]} type="checkbox" label="Active company" />
          <.input field={f[:founded_at]} label="Founded at" type="date" />
          <.input field={f[:established_at]} label="Established at" type="date" />
        </div>

        <div class="flex items-center gap-3">
          <.button type="submit" phx-disable-with="Saving..." class="btn btn-primary">
            {if @action == :new, do: "Create company", else: "Save changes"}
          </.button>
          <.link patch={@patch} class="btn btn-ghost">
            Cancel
          </.link>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("validate", %{"company" => company_params}, socket) do
    changeset =
      socket.assigns.company
      |> Companies.change_company(company_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"company" => company_params}, socket) do
    save_company(socket, socket.assigns.action, company_params)
  end

  defp save_company(socket, :edit, company_params) do
    case Companies.update_company(socket.assigns.company, company_params) do
      {:ok, %{company: company}} ->
        notify_parent({:saved, company})

        {:noreply,
         socket
         |> put_flash(:info, "Company updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, :company, %Ecto.Changeset{} = changeset, _} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_company(socket, :new, company_params) do
    case Companies.create_company(company_params) do
      {:ok, %{company: company}} ->
        notify_parent({:saved, company})

        {:noreply,
         socket
         |> put_flash(:info, "Company created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, :company, %Ecto.Changeset{} = changeset, _} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg) do
    send(self(), {__MODULE__, msg})
  end
end
