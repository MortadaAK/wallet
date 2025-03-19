defmodule Wallet.Accounts do
  alias Ecto.Multi
  alias Wallet.Accounts.{Account, Transaction}
  alias Wallet.Repo
  import Ecto.Query
  @unique_transaction_amount_window_in_seconds 30 * 60
  def register_account(params) do
    %Account{}
    |> Account.changeset(params)
    |> Repo.insert()
  end

  def find_account_by_token(token) do
    from(a in Account, where: a.token == ^token, limit: 1)
    |> Repo.one()
    |> case do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  def find_account(id, opts \\ []) do
    Account
    |> Repo.get(id, opts)
    |> case do
      nil -> {:error, :not_found}
      account -> {:ok, account}
    end
  end

  def topup(account_id, amount, opts \\ []) do
    unique_transaction_amount_window_in_seconds =
      Keyword.get(
        opts,
        :unique_transaction_amount_window_in_seconds,
        @unique_transaction_amount_window_in_seconds
      )

    insert_transaction(%{
      account_id: account_id,
      amount: amount,
      type: :topup,
      unique_transaction_amount_window_in_seconds: unique_transaction_amount_window_in_seconds
    })
  end

  def charge(account_id, amount, opts \\ []) do
    unique_transaction_amount_window_in_seconds =
      Keyword.get(
        opts,
        :unique_transaction_amount_window_in_seconds,
        @unique_transaction_amount_window_in_seconds
      )

    insert_transaction(%{
      account_id: account_id,
      amount: amount,
      type: :charge,
      unique_transaction_amount_window_in_seconds: unique_transaction_amount_window_in_seconds
    })
  end

  defp insert_transaction(%{
         account_id: account_id,
         type: type,
         amount: amount,
         unique_transaction_amount_window_in_seconds: unique_transaction_amount_window_in_seconds
       }) do
    Multi.new()
    |> Multi.put(:account_id, account_id)
    |> Multi.put(:amount, amount)
    |> Multi.put(:type, type)
    |> Multi.put(
      :unique_transaction_amount_window_in_seconds,
      unique_transaction_amount_window_in_seconds
    )
    |> Multi.run(:account, &load_account/2)
    |> Multi.run(:prev_transaction, &check_latest_transaction/2)
    |> Multi.run(:new_balance, &calculate_new_balance/2)
    |> Multi.run(:transaction, &do_insert_transaction/2)
    |> Multi.run(:update_account, &update_account/2)
    |> Repo.transaction()
    |> case do
      {:ok, data} -> {:ok, data}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  defp load_account(_repo, %{account_id: account_id}) do
    # we are locking the account to prevent concurrent transactions recorded to the same account
    # also to prevent any deadlock since we are going to modify the record to store the final balance
    find_account(account_id, lock: "for update")
  end

  defp check_latest_transaction(repo, %{
         type: type,
         amount: amount,
         account_id: account_id,
         unique_transaction_amount_window_in_seconds: unique_transaction_amount_window_in_seconds
       }) do
    # this implementation will prevent duplicate transactions within a window even if they are not in sequence
    since =
      DateTime.shift(DateTime.utc_now(), second: -unique_transaction_amount_window_in_seconds)

    from(t in Transaction,
      where:
        t.account_id == ^account_id and
          t.type == ^type and
          t.amount == ^amount and
          t.inserted_at >= ^since,
      limit: 1
    )
    |> repo.one()
    |> case do
      nil -> {:ok, nil}
      transaction -> {:error, Transaction.duplicate_error(transaction)}
    end
  end

  defp do_insert_transaction(repo, %{
         type: type,
         account: account,
         amount: amount,
         new_balance: new_balance
       }) do
    %Transaction{}
    |> Transaction.changeset(%{
      type: type,
      account_id: account.id,
      sequence: account.next_transaction_sequence,
      amount: amount,
      new_balance: new_balance
    })
    |> repo.insert()
  end

  defp calculate_new_balance(_repo, %{amount: amount, type: :topup, account: %{balance: balance}}),
    do: {:ok, Decimal.add(balance, amount)}

  defp calculate_new_balance(_repo, %{amount: amount, type: :charge, account: %{balance: balance}}),
       do: {:ok, Decimal.sub(balance, amount)}

  defp update_account(repo, %{account: account, new_balance: new_balance}) do
    account
    |> Account.changeset(%{
      balance: new_balance,
      next_transaction_sequence: account.next_transaction_sequence + 1
    })
    |> repo.update()
  end
end
