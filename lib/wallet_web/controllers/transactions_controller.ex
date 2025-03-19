defmodule WalletWeb.TransactionsController do
  use WalletWeb, :controller
  alias Wallet.Accounts

  @doc """

  ## Request:
    - Method: GET
    - Path: /api/transactions

  ## Responses:
    - `200 OK`
      returns the created account
      ```json
      {
        "status": "ok",
        "data": [
          {"transaction_id": 1,"amount": "100.00", "at": "2025-03-19T21:24:15","type": "topup", "balance": "100.00"},
          {"transaction_id": 2,"amount": "50.00", "at": "2025-03-19T21:24:15","type": "charge", "balance": "50.00"}
        ]
      }
      ```


  we are going to use this to preload the transactions and embeds it to the account repose
  in real system, we should paginate them instead of returning all of them
  """
  def transactions(%{assigns: %{account: account}} = conn, _params) do
    transactions = Accounts.transactions_for(account.id)

    conn
    |> put_status(:ok)
    |> json(%{status: "ok", data: Enum.map(transactions, &transaction_payload/1)})
  end

  @doc """

  ## Request:
    - Method: POST
    - Path: /api/transactions/topup
    - Payload:
    ```json
    {"transaction": {"amount": "100"}}
    ```

  ## Responses:
    - `200 OK`
      returns the created transaction
      ```json
      {
        "status": "ok",
        "data": {"transaction_id": 1,"amount": "100.00", "at": "2025-03-19T21:24:15","type": "topup", "balance": "100.00"}
      }
      ```
    - `406`
      returns any error
      ```json
      {
        "status": "error",
        "errors": {
          "amount": ["must be greater than 0"]
        }
      }
      ```
  """
  def topup(%{assigns: %{account: account}} = conn, params) do
    amount = params |> Map.get("transaction", %{}) |> Map.get("amount", "0")

    case Accounts.topup(account.id, amount) do
      {:ok, %{transaction: transaction}} ->
        transaction_response(conn, transaction)

      {:error, changeset} ->
        conn
        |> put_status(406)
        |> json(%{status: "error", errors: traverse_errors(changeset)})
    end
  end

  @doc """

  ## Request:
    - Method: POST
    - Path: /api/transactions/charge
    - Payload:
    ```json
    {"transaction": {"amount": "100"}}
    ```

  ## Responses:
    - `200 OK`
      returns the created transaction
      ```json
      {
        "status": "ok",
        "data": {"transaction_id": 1,"amount": "100.00", "at": "2025-03-19T21:24:15","type": "charge", "balance": "100.00"}
      }
      ```
    - `406`
      returns any error
      ```json
      {
        "status": "error",
        "errors": {
          "amount": ["must be greater than 0"]
        }
      }
      ```
  """
  def charge(%{assigns: %{account: account}} = conn, params) do
    amount = params |> Map.get("transaction", %{}) |> Map.get("amount", "0")

    case Accounts.charge(account.id, amount) do
      {:ok, %{transaction: transaction}} ->
        transaction_response(conn, transaction)

      {:error, changeset} ->
        conn
        |> put_status(406)
        |> json(%{status: "error", errors: traverse_errors(changeset)})
    end
  end

  defp transaction_response(conn, transaction) do
    conn
    |> put_status(:ok)
    |> json(%{status: "ok", data: transaction_payload(transaction)})
  end

  defp transaction_payload(transaction) do
    %{
      transaction_id: transaction.id,
      amount: transaction.amount,
      at: transaction.inserted_at,
      type: transaction.type,
      balance: transaction.new_balance
    }
  end
end
