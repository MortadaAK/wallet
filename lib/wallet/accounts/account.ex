defmodule Wallet.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset
  @token_size 32
  schema "accounts" do
    field :name, :string
    field :next_transaction_sequence, :integer, default: 1
    field :balance, :decimal, default: Decimal.new(0)
    # just a simple way for api authentication
    # in real system we should store them in a different table to be able to allow multiple tokens and
    # able to logout each one by its own or log all of them. Also, so we can add time restrictions ...etc
    field :token, :string
    has_many :transactions, Wallet.Accounts.Transaction, preload_order: [asc: :sequence]
    timestamps()
  end

  def changeset(%__MODULE__{} = account, params) do
    account
    |> cast(params, [:name, :balance, :next_transaction_sequence])
    |> put_new_token_if_not_exists()
    |> validate_required([:name, :token, :next_transaction_sequence, :balance])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
    |> unique_constraint(:token)
  end

  defp put_new_token_if_not_exists(changeset) do
    case get_field(changeset, :token) do
      nil -> put_token(changeset)
      _ -> changeset
    end
  end

  defp put_token(changeset) do
    token = @token_size |> :crypto.strong_rand_bytes() |> Base.encode64() |> String.slice(0..31)
    put_change(changeset, :token, token)
  end
end
