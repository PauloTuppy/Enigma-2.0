defmodule FraudSystemWeb.Router do
  use FraudSystemWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", FraudSystemWeb do
    pipe_through :api
  end
end
