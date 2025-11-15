defmodule AppWeb.UserSessionHTML do
  use AppWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:app, App.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
