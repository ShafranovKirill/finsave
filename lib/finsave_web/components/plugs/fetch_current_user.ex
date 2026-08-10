defmodule FinsaveWeb.Plugs.FetchCurrentUser do
  import Plug.Conn
  alias Finsave.Identity

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :account_id) do
      nil ->
        assign(conn, :current_user, nil)

      user_id ->
        case Identity.get_account(user_id) do
          {:ok, account} ->
            assign(conn, :current_user, account)

          _ ->
            conn
            |> delete_session(:account_id)
            |> assign(:current_user, nil)
        end
    end
  end
end
