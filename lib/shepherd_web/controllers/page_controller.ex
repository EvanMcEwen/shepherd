defmodule ShepherdWeb.PageController do
  use ShepherdWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
