use Mix.Config

# Configure your database
config :never_lose_tic_tac_toe, NeverLoseTicTacToe.Repo,
  username: "postgres",
  password: "postgres",
  database: "never_lose_tic_tac_toe_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :never_lose_tic_tac_toe, NeverLoseTicTacToeWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
