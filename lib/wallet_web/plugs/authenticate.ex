defmodule WalletWeb.Authenticate do
  @behaviour Plug
  alias Wallet.Accounts

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    with {:ok, token} <- get_token(conn),
         {:ok, account} <- Accounts.find_account_by_token(token) do
      Plug.Conn.assign(conn, :account, account)
    else
      _ ->
        conn
        |> Plug.Conn.put_status(:unauthorized)
        |> Phoenix.Controller.json(%{status: "error", errors: %{account: "Unauthorized"}})
        |> Plug.Conn.halt()
    end
  end

  defp get_token(conn) do
    case Plug.Conn.get_req_header(conn, "authorization") do
      ["Bearer " <> token] when byte_size(token) > 0 -> {:ok, token}
      _ -> :error
    end
  end
end
