defmodule FinsaveWeb.Hooks.Auth do
  import Phoenix.LiveView
  import Phoenix.Component
  alias Finsave.Identity

  def on_mount(:default, _params, session, socket) do
    locale = FinsaveWeb.Plugs.Locale.restore_from_session(session)

    socket = assign(socket, :locale, locale)

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

  def on_mount(:require_authenticated_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, redirect(socket, to: "/auth/login")}
    end
  end
end
