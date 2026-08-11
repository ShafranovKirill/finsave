defmodule FinsaveWeb.RedirectController do
  use FinsaveWeb, :controller

  def to_login(conn, _params) do
    conn
    |> redirect(to: "/auth/login")
  end
end
