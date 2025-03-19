defmodule WalletWeb.TransactionsTest do
  use WalletWeb.ConnCase, async: true
  alias Wallet.Accounts

  describe "POST /api/transactions/topup" do
    test "should return error if the request doesn't have token", %{conn: conn} do
      conn = post(conn, "/api/transactions/topup", %{transaction: %{amount: 1}})

      assert %{"errors" => %{"account" => "Unauthorized"}, "status" => "error"} ==
               json_response(conn, 401)
    end

    test "should add to the account", %{conn: conn} do
      assert {:ok, %{token: token}} = Accounts.register_account(%{name: "Mohammad"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/transactions/topup", %{transaction: %{amount: 1}})

      assert %{
               "status" => "ok",
               "data" => %{
                 "amount" => "1.00",
                 "at" => _,
                 "balance" => "1.00",
                 "transaction_id" => _,
                 "type" => "topup"
               }
             } =
               json_response(conn, 200)
    end

    test "should return error for invalid amount", %{conn: conn} do
      assert {:ok, %{token: token}} = Accounts.register_account(%{name: "Mohammad"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/transactions/topup", %{transaction: %{amount: -1}})

      assert %{
               "status" => "error",
               "errors" => %{
                 "amount" => ["must be greater than 0"],
                 "new_balance" => ["must be greater than or equal to 0"]
               }
             } =
               json_response(conn, 406)
    end

    test "should return error for amount with more than 2 decimal digits", %{conn: conn} do
      assert {:ok, %{token: token}} = Accounts.register_account(%{name: "Mohammad"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/transactions/topup", %{transaction: %{amount: "1.123"}})

      assert %{"errors" => %{"amount" => ["at most 2 decimal points"]}, "status" => "error"} =
               json_response(conn, 406)
    end
  end

  describe "POST /api/transactions/charge" do
    test "should return error if the request doesn't have token", %{conn: conn} do
      conn = post(conn, "/api/transactions/charge", %{transaction: %{amount: 1}})

      assert %{"errors" => %{"account" => "Unauthorized"}, "status" => "error"} ==
               json_response(conn, 401)
    end

    test "should add to the account", %{conn: conn} do
      assert {:ok, %{token: token, id: account_id}} =
               Accounts.register_account(%{name: "Mohammad"})

      assert {:ok, _} = Accounts.topup(account_id, 100)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/transactions/charge", %{transaction: %{amount: 1}})

      assert %{
               "status" => "ok",
               "data" => %{
                 "amount" => "1.00",
                 "at" => _,
                 "balance" => "99.00",
                 "transaction_id" => _,
                 "type" => "charge"
               }
             } =
               json_response(conn, 200)
    end

    test "should return error for invalid amount", %{conn: conn} do
      assert {:ok, %{token: token}} = Accounts.register_account(%{name: "Mohammad"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/transactions/charge", %{transaction: %{amount: -1}})

      assert %{
               "status" => "error",
               "errors" => %{
                 "amount" => ["must be greater than 0"]
               }
             } =
               json_response(conn, 406)
    end

    test "should return error for amount with more than 2 decimal digits", %{conn: conn} do
      assert {:ok, %{token: token}} = Accounts.register_account(%{name: "Mohammad"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/api/transactions/charge", %{transaction: %{amount: "1.123"}})

      assert %{"errors" => %{"amount" => ["at most 2 decimal points"]}, "status" => "error"} =
               json_response(conn, 406)
    end
  end

  describe "GET /api/transactions" do
    test "should return error if the request doesn't have token", %{conn: conn} do
      conn = get(conn, "/api/transactions")

      assert %{"errors" => %{"account" => "Unauthorized"}, "status" => "error"} ==
               json_response(conn, 401)
    end

    test "should return the list of transactions", %{conn: conn} do
      assert {:ok, %{token: token, id: account_id}} =
               Accounts.register_account(%{name: "Mohammad"})

      assert {:ok, _} = Accounts.topup(account_id, 100)
      assert {:ok, _} = Accounts.charge(account_id, 10)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/transactions")

      assert %{
               "status" => "ok",
               "data" => [
                 %{
                   "amount" => "100.00",
                   "at" => _,
                   "balance" => "100.00",
                   "transaction_id" => _,
                   "type" => "topup"
                 },
                 %{
                   "amount" => "10.00",
                   "at" => _,
                   "balance" => "90.00",
                   "transaction_id" => _,
                   "type" => "charge"
                 }
               ]
             } =
               json_response(conn, 200)
    end
  end
end
