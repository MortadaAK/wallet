# Wallet

This is an example project that simulate a system that has
- multiple account
- each account should have a balance
- an endpoint that register new account
- an endpoint that retrieves account information
- an endpoint that retrieves account transactions
- an endpoint to record topups
- an endpoint to record charges
- this support simple authorization system using bearer token per account

## Endpoints
- POST /api/register
- GET /api/account
- GET /api/transactions
- POST /api/transactions/topup
- POST /api/transactions/charge


## Framework/Language
We are using Elixir as the backend and Phoenix for the framework here is why:
- *Scalability & Concurrency*: Elixir runs on the BEAM VM, making it highly efficient for handling concurrent requests.
- *Fault Tolerance*: The supervision tree architecture ensures system reliability and self-healing capabilities.
- *Performance*: Lightweight processes allow efficient handling of thousands of requests with minimal overhead.
- *Maintainability*: Functional programming and clear syntax lead to clean, maintainable code.
- *Real-time Capabilities*: Excellent for real-time applications due to Phoenix Channels and WebSockets support.
- *Robust Ecosystem*: The Phoenix framework provides built-in support for REST, GraphQL, and WebSockets.
- *Developer Productivity*: Features like pattern matching, pipelines, and immutability lead to fewer bugs and faster development.
- *Strong Testing Support*: The built-in ExUnit framework makes writing and maintaining tests seamless.
- *Ease of Deployment*: Elixir’s releases and hot upgrades simplify deployment and operational efficiency.
- *Growing Adoption*: Used by companies like Discord, Pinterest, and WhatsApp for high-performance applications.

For more information about it

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

## Starting up the dev server using docker-compose

create the compose cluster

```sh
docker-compose up
```

this will setup postgres, Elixir and install all dependencies and migrate the database

then you can access it at [`localhost:4000`](http://localhost:4000)