defmodule WalletWeb.AccountsController do
  use WalletWeb, :controller
  alias Wallet.Accounts

  @doc """

  ## Request:
    - Method: POST
    - Path: /api/register
    - Payload:
      ```json
        {
        "account": {
          "name": "Mohammad"
          }
        }
      ```

  ## Responses:
    - `200 OK`
      returns the created account
      ```json
      {"status": "ok","data": {"account_id": 1, "balance": "0", token: ""}}
      ```
    - `406`
      returns the error
      ```json
      {"status": "error","errors": {"name": ["already taken"]}}
      ```
  """
  def register(conn, params) do
    params
    |> Map.get("account", %{})
    |> Map.take(["name"])
    |> Accounts.register_account()
    |> case do
      {:ok, account} ->
        account_response(conn, account)

      {:error, changeset} ->
        conn
        |> put_status(406)
        |> json(%{status: "error", errors: traverse_errors(changeset)})
    end
  end

  @doc """

  ## Request:
    - Method: GET
    - Path: /api/account

  ## Responses:
    - `200 OK`
      returns the created account
      ```json
      {"status": "ok","data": {"name": "Mohammad","account_id": 1, "balance": "0", token: ""}}
      ```
  """
  def account(%{assigns: %{account: account}} = conn, _params) do
    account_response(conn, account)
  end

  defp account_response(conn, account) do
    conn
    |> put_status(:ok)
    |> json(%{
      status: "ok",
      data: %{
        account_id: account.id,
        balance: account.balance,
        # we should not include the token in every response but in this demo we are since we don't have a full
        # authentication system
        token: account.token,
        name: account.name
      }
    })
  end
end
