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
      <%= raw @board_html %>
      </div>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, update_socket(socket, board_from_board_size("3x3"))}
  end

  def handle_event("human-move", cell_index, %{assigns: %{board: board}} = socket) do
    new_board =
      board
      |> update_human_move(cell_index)
      |> update_computer_move()

    {:noreply, update_socket(socket, new_board)}
  end

  def handle_event("board-size-choose", board_size, socket) do
    {:noreply, update_socket(socket, board_from_board_size(board_size))}
  end

  defp update_socket(socket, board) do
    socket
    |> assign(:board_html, build_board_html(board))
    |> assign(:board, board)
  end

  defp board_from_board_size("3x3"), do: @board_3_x_3
  defp board_from_board_size("4x4"), do: @board_4_x_4
  defp board_from_board_size("5x5"), do: @board_5_x_5

  defp build_board_html(board) do
    {rows, _} =
      Enum.reduce(board, {"", 0}, fn row, {rows, row_index} ->
        {columns, _} =
          Enum.reduce(row, {"", 0}, fn
            "0", {columns, column_index} -> row(columns, row_index, column_index, "O")
            "1", {columns, column_index} -> row(columns, row_index, column_index, "X")
            "x", {columns, column_index} -> row(columns, row_index, column_index)
          end)

        {rows <> "<tr>#{columns}</tr>", row_index + 1}
      end)

    "<table> #{rows} </table>"
  end

  defp row(columns, row_index, column_index) do
    {
      columns <>
        "<td class=\"cell\"><button value=\"#{row_index}x#{column_index}\" phx-click=\"human-move\"></button></td>",
      column_index + 1
    }
  end

  defp row(columns, row_index, column_index, cell_value) do
    {
      columns <> "<td class=\"cell\" value=\"#{row_index}x#{column_index}\">#{cell_value}</td>",
      column_index + 1
    }
  end

  defp replace_element_in_board(board, [x, y], text_to_replace) do
    new_row = board |> Enum.at(x) |> List.replace_at(y, text_to_replace)
    board |> List.replace_at(x, new_row)
  end

  defp handle_human_move(board, cell_index) do
    [x, y] = String.split(cell_index, "x") |> Enum.map(&String.to_integer(&1))
    replace_element_in_board(board, [x, y], "1")
  end

  defp update_computer_move(board, cell_index) do
    [x, y] = find_next_possible_winning_move(board)
    replace_element_in_board(board, [x, y], "O")
  end
end
