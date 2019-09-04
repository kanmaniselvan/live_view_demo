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

  @board_7_x_7 [
    ~w(x x x x x x x),
    ~w(x x x x x x x),
    ~w(x x x x x x x),
    ~w(x x x 0 x x x),
    ~w(x x x x x x x),
    ~w(x x x x x x x),
    ~w(x x x x x x x)
  ]

  defp board_select_html() do
    """
    <div class="board-select-cont">    
      <button phx-click="board-size-choose" value="3x3">3 x 3</button>
      <button phx-click="board-size-choose" value="5x5">5 x 5</button>
      <button phx-click="board-size-choose" value="7x7">7 x 7</button>
    </div>  
    """
  end

  def render(%{game_state: :playing} = assigns) do
    ~L"""
    <div>
      <%= raw board_select_html() %>
      <div id="game-board">
        <%= raw @board_html %>
      </div>
    </div>
    """
  end

  def render(%{game_state: :game_draw} = assigns) do
    ~L"""
    <div>
      <%= raw board_select_html() %>
      <div id="game-board">
        <%= raw @board_html %>
      </div>
    </div>
    """
  end

  def render(%{game_state: :computer_won} = assigns) do
    ~L"""
    <div>
      <%= raw board_select_html() %>
      <div id="game-board">4
        <%= raw @board_html %>
      </div>
    </div>
    """
  end

  def mount(_session, socket) do
    {:ok, update_socket(socket, board_from_board_size("3x3"), {:playing, []})}
  end

  def handle_event("human-move", cell_index_string, %{assigns: %{board: board}} = socket) do
    cell_index = cell_index(cell_index_string)

    new_board =
      board
      |> handle_human_move(cell_index)
      |> handle_computer_move(cell_index)

    {:noreply, update_socket(socket, new_board, game_status(new_board))}
  end

  def handle_event("board-size-choose", board_size, socket) do
    {:noreply, update_socket(socket, board_from_board_size(board_size), {:playing, []})}
  end

  defp update_socket(socket, board, {game_state, won_cells}) do
    socket
    |> assign(:game_state, game_state)
    |> assign(:won_cells, won_cells)
    |> assign(:board_html, build_board_html(board))
    |> assign(:board, board)
  end

  defp board_from_board_size("3x3"), do: @board_3_x_3
  defp board_from_board_size("5x5"), do: @board_5_x_5
  defp board_from_board_size("7x7"), do: @board_7_x_7

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
    String.split(cell_index, "x") |> Enum.map(&String.to_integer(&1)) |> List.to_tuple()
  end

  defp replace_element_in_board(board, {_, :not_found}, _text_to_replace), do: board

  defp replace_element_in_board(board, {x, y}, text_to_replace) do
    new_row = board |> Enum.at(x) |> List.replace_at(y, text_to_replace)
    board |> List.replace_at(x, new_row)
  end

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
        {[{x, index} | free_cells], index + 1, human_entries}

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
            {[{index, y} | free_cells], index + 1, human_entries}

          "1" ->
            {free_cells, index + 1, human_entries + 1}

          "0" ->
            {free_cells, index + 1, human_entries}
        end
    end)
  end

  defp free_cell_index(board) do
    Enum.reduce_while(board, {0, :not_found}, fn row, {x, _} ->
      {y_found, y} =
        Enum.reduce_while(row, {true, 0}, fn
          "x", {_, index} -> {:halt, {:found, index}}
          _, {_, index} -> {:cont, {:not_found, index + 1}}
        end)

      if y_found == :found, do: {:halt, {x, y}}, else: {:cont, {x + 1, :not_found}}
    end)
  end

  defp find_next_possible_winning_move(board, {x, y}) do
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

  defp update_in_elem_1({elem_1, elem_2, elem_3, y}, elem) do
    {[elem | elem_1], elem_2, elem_3, y}
  end

  defp update_in_elem_2({elem_1, elem_2, elem_3, y}, elem) do
    {elem_1, [elem | elem_2], elem_3, y}
  end

  defp update_in_elem_3({elem_1, elem_2, elem_3, y}, elem) do
    {elem_1, elem_2, [elem | elem_3], y}
  end

  defp detect_computer_won_x_and_xy_and_yx_cells(board) do
    board_size = Enum.count(board)
    end_index = board_size - 1

    Enum.reduce_while(board, {:not_found, [], [], [], 0, end_index}, fn row,
                                                                        {_, _x_cells, xy_cells,
                                                                         yx_cells, x, yx} ->
      {x_cells, xy_cells, yx_cells, _index} =
        Enum.reduce(row, {[], xy_cells, yx_cells, 0}, fn
          "0", {x_cells, xy_cells, yx_cells, y} ->
            cond do
              x == y && y == yx ->
                {x_cells, xy_cells, yx_cells, y + 1}
                |> update_in_elem_1({x, y})
                |> update_in_elem_2({x, y})
                |> update_in_elem_3({x, y})

              x == y ->
                {x_cells, xy_cells, yx_cells, y + 1}
                |> update_in_elem_1({x, y})
                |> update_in_elem_2({x, y})

              y == yx ->
                {x_cells, xy_cells, yx_cells, y + 1}
                |> update_in_elem_1({x, y})
                |> update_in_elem_3({x, y})

              true ->
                {x_cells, xy_cells, yx_cells, y + 1}
                |> update_in_elem_1({x, y})
            end

          _, {x_cells, xy_cells, yx_cells, y} ->
            {x_cells, xy_cells, yx_cells, y + 1}
        end)

      cond do
        Enum.count(x_cells) == board_size -> {:halt, {:found, x_cells}}
        Enum.count(xy_cells) == board_size -> {:halt, {:found, xy_cells}}
        Enum.count(yx_cells) == board_size -> {:halt, {:found, yx_cells}}
        true -> {:cont, {:not_found, [], xy_cells, yx_cells, x + 1, yx - 1}}
      end
    end)
  end

  defp detect_computer_won_y_cells(board) do
    board_size = Enum.count(board)
    end_index = board_size - 1

    Enum.reduce_while(0..end_index, {:not_found, []}, fn x, {_, _y_cells} ->
      {y_cells, _y_index} =
        Enum.reduce(board, {[], 0}, fn rows, {y_cells, y} ->
          if Enum.at(rows, x) == "0" do
            {[{x, y} | y_cells], y + 1}
          else
            {y_cells, y + 1}
          end
        end)

      cond do
        Enum.count(y_cells) == board_size -> {:halt, {:found, y_cells}}
        true -> {:cont, {:not_found, []}}
      end
    end)
  end

  defp computer_won(board) do
    with {:found, won_cells} <- detect_computer_won_x_and_xy_and_yx_cells(board) do
      {:ok, won_cells}
    else
      _ ->
        with {:found, won_cells} <- detect_computer_won_y_cells(board) do
          {:ok, won_cells}
        else
          _ -> {:not_found, []}
        end
    end
  end

  defp game_draw({_, :not_found}), do: true
  defp game_draw({_, _}), do: false

  defp game_status(board) do
    with {:ok, won_cells} <- computer_won(board) do
      {:computer_won, won_cells}
    else
      _ ->
        cond do
          board |> free_cell_index |> game_draw -> {:game_draw, []}
          true -> {:playing, []}
        end
    end
  end
end
