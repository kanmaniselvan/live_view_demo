defmodule NeverLoseTicTacToeWeb.PageController do
  use NeverLoseTicTacToeWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
