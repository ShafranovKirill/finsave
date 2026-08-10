defmodule FinsaveWeb.Hooks.Auth do
  import Phoenix.Component
  alias Finsave.Identity

  def on_mount(:default, _params, session, socket) do
    default_locale = Application.get_env(:finsave, :default_locale) || "en"

    locale = session["locale"] || default_locale
    Gettext.put_locale(FinsaveWeb.Gettext, locale)

    case session["account_id"] do
      nil ->
        {:cont, assign(socket, :current_user, nil)}

      account_id ->
        case Identity.get_account(account_id) do
          {:ok, account} ->
            socket =
              assign(socket, :current_user, account)

            {:cont, socket}

          _ ->
            {:cont, assign(socket, :current_user, nil)}
        end
    end
  end
end
