defmodule NeverLoseTicTacToeWeb.NeverLoseTicTacToeLive do
  use Phoenix.LiveView
  import Phoenix.HTML

  @board_3_x_3 [
    ~w(x x x),
    ~w(x 0 x),
    ~w(x x x)
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

  def handle_event("human-move", cell_index_string, %{assigns: %{board: board}} = socket) do
    cell_index = cell_index(cell_index_string)

    new_board =
      board
      |> handle_human_move(cell_index)
      |> handle_computer_move(cell_index)

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

  defp cell_index(cell_index) do
    String.split(cell_index, "x") |> Enum.map(&String.to_integer(&1))
  end

  defp replace_element_in_board(board, [x, y], text_to_replace) do
    new_row = board |> Enum.at(x) |> List.replace_at(y, text_to_replace)
    board |> List.replace_at(x, new_row)
  end

  defp replace_element_in_board(board, [_, false], _text_to_replace), do: board

  defp handle_human_move(board, cell_index) do
    replace_element_in_board(board, cell_index, "1")
  end

  defp handle_computer_move(board, cell_index) do
    next_move_index = find_next_possible_winning_move(board, cell_index)
    replace_element_in_board(board, next_move_index, "0")
  end

  defp x_cell_to_block(board, x) do
    x_cells = board |> Enum.at(x)

    Enum.reduce(x_cells, {[], 0, 0}, fn
      "x", {free_cells, index, human_entries} ->
        {[[x, index] | free_cells], index + 1, human_entries}

      "1", {free_cells, index, human_entries} ->
        {free_cells, index + 1, human_entries + 1}

      "0", {free_cells, index, human_entries} ->
        {free_cells, index + 1, human_entries}
    end)
  end

  defp y_cell_to_block(board, y) do
    Enum.reduce(board, {[], 0, 0}, fn
      x_cells, {free_cells, index, human_entries} ->
        case Enum.at(x_cells, y) do
          "x" ->
            {[[index, y] | free_cells], index + 1, human_entries}

          "1" ->
            {free_cells, index + 1, human_entries + 1}

          "0" ->
            {free_cells, index + 1, human_entries}
        end
    end)
  end

  defp free_cell_index(board) do
    Enum.reduce_while(board, [0, false], fn row, [x, _] ->
      {y_found, y} =
        Enum.reduce_while(row, {true, 0}, fn
          "x", {_, index} -> {:halt, {true, index}}
          _, {_, index} -> {:cont, {false, index + 1}}
        end)

      if y_found, do: {:halt, [x, y]}, else: {:cont, [x + 1, false]}
    end)
  end

  defp find_next_possible_winning_move(board, [x, y]) do
    {x_free_cells, _, x_human_entries} = x_cell_to_block(board, x)
    {y_free_cells, _, y_human_entries} = y_cell_to_block(board, y)

    cond do
      x_human_entries >= y_human_entries && Enum.count(x_free_cells) != 0 ->
        List.last(x_free_cells)

      Enum.count(y_free_cells) != 0 ->
        List.last(y_free_cells)

      true ->
        free_cell_index(board)
    end
  end
end
