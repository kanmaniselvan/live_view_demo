defmodule NeverLoseTicTacToe.Repo do
  use Ecto.Repo,
    otp_app: :never_lose_tic_tac_toe,
    adapter: Ecto.Adapters.Postgres
end
