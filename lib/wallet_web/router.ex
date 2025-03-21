defmodule WalletWeb.Router do
  use WalletWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug WalletWeb.Authenticate
  end

  scope "/api", WalletWeb do
    pipe_through :api

    post "/register", AccountsController, :register
  end

  scope "/api", WalletWeb do
    pipe_through [:api, :authenticated]
    get "/account", AccountsController, :account
    get "/transactions", TransactionsController, :transactions
    post "/transactions/topup", TransactionsController, :topup
    post "/transactions/charge", TransactionsController, :charge
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:wallet, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: WalletWeb.Telemetry
    end
  end
end
