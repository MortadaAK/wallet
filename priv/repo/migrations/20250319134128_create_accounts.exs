defmodule Wallet.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table("accounts") do
      add :name, :string, null: false
      add :next_transaction_sequence, :bigint, null: false, default: 1
      add :balance, :decimal, null: false, default: 0
      add :token, :string, null: false
      timestamps()
    end

    create unique_index("accounts", :token)
    create unique_index("accounts", :name)
    create constraint("accounts", "non_neg_balance", check: "balance >= 0")
    create constraint("accounts", "non_neg_sequence", check: "next_transaction_sequence >= 0")
  end
end
