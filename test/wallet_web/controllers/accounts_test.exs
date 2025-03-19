defmodule WalletWeb.AccountsTest do
  alias Wallet.Accounts
  use WalletWeb.ConnCase, async: true

  describe "POST /api/register" do
    test "should create new account", %{conn: conn} do
      conn = post(conn, "/api/register", %{account: %{name: "Mohammad"}})

      assert %{
               "data" => %{
                 "account_id" => account_id,
                 "balance" => "0",
                 "token" => token
               },
               "status" => "ok"
             } = json_response(conn, 200)

      assert {:ok, %{name: "Mohammad"}} = Accounts.find_account(account_id)
      assert String.length(token) == 32
    end

    test "should return error", %{conn: conn} do
      assert {:ok, _} = Accounts.register_account(%{name: "Mohammad"})
      conn = post(conn, "/api/register", %{account: %{name: "Mohammad"}})

      assert %{
               "errors" => %{"name" => ["has already been taken"]},
               "status" => "error"
             } = json_response(conn, 406)
    end
  end

  describe "GET /api/account" do
    test "should return error when the token is not passed", %{conn: conn} do
      conn = get(conn, "/api/account")

      assert %{"errors" => %{"account" => "Unauthorized"}, "status" => "error"} ==
               json_response(conn, 401)
    end

    test "should return account information", %{conn: conn} do
      assert {:ok, %{token: token, id: id}} = Accounts.register_account(%{name: "Mohammad"})

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get("/api/account")

      assert %{
               "status" => "ok",
               "data" => %{
                 "account_id" => ^id,
                 "balance" => "0",
                 "name" => "Mohammad",
                 "token" => ^token
               }
             } =
               json_response(conn, 200)
    end
  end
end
