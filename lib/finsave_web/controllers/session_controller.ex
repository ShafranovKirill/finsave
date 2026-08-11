defmodule FinsaveWeb.SessionController do
  use FinsaveWeb, :controller
  alias Finsave.Identity

  def create(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Identity.authentificate(email, password) do
      {:ok, account} ->
        conn
        |> put_session(:account_id, account.id)
        |> put_flash(:info, gettext("Successfuly logged in!"))
        |> redirect(to: "/dashboard")

      {:error, :invalid_credentials} ->
        conn
        |> put_flash(:error, gettext("Authetification failed."))
        |> redirect(to: "/auth/login")
    end
  end

  def delete(conn, _params) do
    conn
    |> clear_session()
    |> put_flash(:info, gettext("Logged out successfully."))
    |> redirect(to: "/")
  end
end
