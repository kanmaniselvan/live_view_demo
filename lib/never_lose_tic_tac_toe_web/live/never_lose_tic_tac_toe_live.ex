defmodule NeverLoseTicTacToeWeb.NeverLoseTicTacToeLive do
  use Phoenix.LiveView
  import Phoenix.HTML

  @board_3_x_3 [
    ~w(x x x),
    ~w(x 0 x),
    ~w(x x x)
  ]

  @board_4_x_4 [
    ~w(x x x x),
    ~w(x x x x),
    ~w(x x 0 x),
    ~w(x x x x)
  ]

  @board_5_x_5 [
    ~w(x x x x x),
    ~w(x x x x x),
    ~w(x x 0 x x),
    ~w(x x x x x),
    ~w(x x x x x)
  ]

  def render(assigns) do
    ~L"""
    <div>
    <h1>Select board size </h1>
     <button phx-click="board-size-choose" value="3x3">3 x 3</button>
     <button phx-click="board-size-choose" value="4x4">4 x 4</button>
     <button phx-click="board-size-choose" value="5x5">5 x 5</button>
    </div>
    <div>
      <div class="note"> O - Computer | X - You </div>
      <div id="game-board">
      <%= raw @board %>
      </div>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, put_data(socket, "3x3")}
  end

  def handle_event("board-size-choose", board, socket) do
    {:noreply, put_data(socket, board)}
  end

  defp put_data(socket, board) do
    board =
      case board do
        "3x3" -> @board_3_x_3
        "4x4" -> @board_4_x_4
        "5x5" -> @board_5_x_5
      end

    assign(socket, :board, build_board(board))
  end

  defp build_board(board) do
    rows =
      Enum.reduce(board, "", fn row, rows ->
        columns =
          Enum.reduce(row, "", fn
            "0", columns -> "<td>0</td>" <> columns
            cell, columns -> "<td></td>" <> columns
          end)

        "<tr>#{columns}</tr>" <> rows
      end)

    "<table> #{rows} </table>"
  end
end
