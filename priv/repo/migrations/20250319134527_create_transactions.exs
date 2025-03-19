defmodule Wallet.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table("transactions") do
      add :account_id, references("accounts"), null: false
      add :sequence, :bigint, null: false
      add :amount, :decimal, null: false
      add :type, :string, null: false
      add :new_balance, :decimal, null: false
      timestamps()
    end

    create unique_index("transactions", [:account_id, :sequence])
  end
end
