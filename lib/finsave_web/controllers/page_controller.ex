defmodule FinsaveWeb.PageController do
  use FinsaveWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
