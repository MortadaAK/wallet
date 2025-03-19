defmodule Wallet.AccountsTest do
  use Wallet.DataCase, async: true
  alias Wallet.{Accounts, Accounts.Account, Accounts.Transaction}

  describe "register_account" do
    test "should insert new account" do
      assert {:ok, %Account{name: "Mohammad", token: token}} =
               Accounts.register_account(%{name: "Mohammad"})

      assert is_binary(token)
      assert 32 == String.length(token)
    end

    test "should prevent duplicate names" do
      assert {:ok, %Account{}} = Accounts.register_account(%{name: "Mohammad"})
      assert {:error, changeset} = Accounts.register_account(%{name: "Mohammad"})
      assert "has already been taken" in errors_on(changeset).name
    end

    test "should prevent balance from going under 0" do
      assert {:error, changeset} = Accounts.register_account(%{name: "Mohammad", balance: -1})
      assert "must be greater than or equal to 0" in errors_on(changeset).balance
    end
  end

  describe "find_account/2" do
    test "should return the account" do
      {:ok, account} = Accounts.register_account(%{name: "Mohammad"})
      assert {:ok, ^account} = Accounts.find_account(account.id)
    end

    test "should return error when the account is not found" do
      assert {:error, :not_found} = Accounts.find_account(0)
    end
  end

  describe "find_account_by_token/1" do
    test "should return the account by token" do
      {:ok, account} = Accounts.register_account(%{name: "Mohammad"})
      assert {:ok, ^account} = Accounts.find_account_by_token(account.token)
    end

    test "should return error when the account is not found" do
      assert {:error, :not_found} = Accounts.find_account_by_token("TOKEN")
    end
  end

  describe "topup/3" do
    setup do
      {:ok, account} = Accounts.register_account(%{name: "Mohammad"})
      {:ok, account: account}
    end

    test "should increment the account balance and next sequence", %{account: account} do
      amount = Decimal.from_float(100.00)

      assert {:ok,
              %{
                type: :topup,
                transaction: %Transaction{
                  sequence: 1,
                  amount: ^amount,
                  type: :topup,
                  new_balance: ^amount
                },
                amount: ^amount,
                new_balance: ^amount,
                account: ^account,
                update_account: %Account{
                  next_transaction_sequence: 2,
                  balance: ^amount
                }
              }} = Accounts.topup(account.id, amount)
    end

    test "should prevent duplicate transactions amount and type within the specified period", %{
      account: account
    } do
      assert {:ok, %{}} = Accounts.topup(account.id, 100)
      assert {:error, changeset} = Accounts.topup(account.id, 100)
      assert "duplicate transaction" in errors_on(changeset).amount
    end

    test "should allow duplicate transactions amount and but with different type",
         %{
           account: account
         } do
      assert {:ok, %{}} = Accounts.topup(account.id, 100)
      assert {:ok, %{}} = Accounts.charge(account.id, 100)
    end

    test "should always use the latest account balance (reload and lock)", %{account: account} do
      assert {:ok, %{}} = Accounts.topup(account.id, 100)
      assert {:ok, %{}} = Accounts.topup(account.id, 200)
      assert {:ok, %{update_account: %{balance: balance}}} = Accounts.topup(account.id, 300)
      assert Decimal.eq?(balance, 600)
    end

    test "should not allow decimals with more than 2 decimal points", %{account: account} do
      assert {:error, changeset} = Accounts.topup(account.id, "100.123")
      assert "at most 2 decimal points" in errors_on(changeset).amount
      assert {:ok, %{new_balance: new_balance}} = Accounts.topup(account.id, "100.12")
      assert Decimal.eq?(new_balance, "100.12")
    end

    test "all amounts must be positive", %{account: account} do
      assert {:error, changeset} = Accounts.topup(account.id, "-1")
      assert "must be greater than 0" in errors_on(changeset).amount
    end
  end

  describe "charge/3" do
    setup do
      {:ok, account} = Accounts.register_account(%{name: "Mohammad"})
      assert {:ok, %{update_account: account}} = Accounts.topup(account.id, 100)
      {:ok, account: account}
    end

    test "should prevent duplicate transactions amount and type within the specified period", %{
      account: account
    } do
      assert {:ok, %{}} = Accounts.charge(account.id, 1)
      assert {:error, changeset} = Accounts.charge(account.id, 1)
      assert "duplicate transaction" in errors_on(changeset).amount
    end

    test "should allow duplicate transactions amount and but with different type",
         %{
           account: account
         } do
      assert {:ok, %{}} = Accounts.charge(account.id, 10)
      assert {:ok, %{}} = Accounts.topup(account.id, 10)
    end

    test "should decrement the account balance and increment next sequence", %{account: account} do
      amount = Decimal.from_float(12.00)
      new_balance = Decimal.from_float(88.00)

      assert {:ok,
              %{
                type: :charge,
                transaction: %Transaction{
                  sequence: 2,
                  amount: ^amount,
                  type: :charge,
                  new_balance: ^new_balance
                },
                amount: ^amount,
                new_balance: ^new_balance,
                account: ^account,
                update_account: %Account{
                  next_transaction_sequence: 3,
                  balance: ^new_balance
                }
              }} = Accounts.charge(account.id, amount)
    end

    test "should prevent account from going negative", %{account: account} do
      assert {:error, changeset} = Accounts.charge(account.id, 200)
      assert "must be greater than or equal to 0" in errors_on(changeset).new_balance
    end

    test "all amounts must be positive", %{account: account} do
      assert {:error, changeset} = Accounts.charge(account.id, "-1")
      assert "must be greater than 0" in errors_on(changeset).amount
    end
  end
end
