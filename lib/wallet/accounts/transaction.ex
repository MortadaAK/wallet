defmodule Wallet.Accounts.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  schema "transactions" do
    belongs_to :account, Wallet.Accounts.Account

    # we use this sequence to ensure that we have the latest state of the account so we don't have any stall balance
    # the way this works in case multiple requests get triggered at the same time and the application will process them concurrently,
    # without this way (if we don't use the database lock) the database will reject the duplicate records based on the sequence
    field :sequence, :integer
    field :amount, :decimal
    field :type, Ecto.Enum, values: [:topup, :charge]
    field :new_balance, :decimal
    timestamps()
  end

  def changeset(%__MODULE__{} = transaction, params) do
    transaction
    |> cast(params, [:account_id, :sequence, :amount, :type, :new_balance])
    |> validate_required([:account_id, :sequence, :amount, :type, :new_balance])
    |> validate_amount()
    |> validate_number(:new_balance, greater_than_or_equal_to: 0)
  end

  defp validate_amount(changeset) do
    changeset
    |> validate_number(:amount, greater_than: 0)
    |> validate_change(:amount, fn field, amount ->
      case Decimal.scale(amount) do
        length when length <= 2 -> []
        _ -> [{field, "at most 2 decimal points"}]
      end
    end)
    |> normalize_amount()
  end

  defp normalize_amount(%{valid?: true} = changeset) do
    amount = get_field(changeset, :amount)
    put_change(changeset, :amount, Decimal.round(amount, 2))
  end

  defp normalize_amount(changeset), do: changeset

  def duplicate_error(%__MODULE__{} = transaction) do
    transaction
    |> change()
    |> add_error(:amount, "duplicate transaction")
  end
end
