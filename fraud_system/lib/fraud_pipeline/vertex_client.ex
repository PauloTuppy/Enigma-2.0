defmodule FraudPipeline.VertexClient do
  @scope "https://www.googleapis.com/auth/cloud-platform"
  @base "https://us-central1-aiplatform.googleapis.com/v1"

  def score_transaction(tx) do
    cfg = Application.get_env(:fraud_system, :vertex_ai)

    project_id = cfg[:project_id]
    location = cfg[:location]
    endpoint_id = cfg[:endpoint_id]

    url =
      "#{@base}/projects/#{project_id}/locations/#{location}/endpoints/#{endpoint_id}:predict"

    body = %{
      instances: [
        %{
          amount_brl: tx["amount_brl"],
          user_risk_score: tx["user_risk_score"] || 0,
          failed_withdrawals_24h: tx["failed_withdrawals_24h"] || 0
        }
      ]
    }

    with {:ok, token} <- Goth.Token.for_scope(@scope),
         {:ok, %HTTPoison.Response{status_code: 200, body: raw}} <-
           HTTPoison.post(url, Jason.encode!(body), [
             {"Authorization", "Bearer #{token.token}"},
             {"Content-Type", "application/json"}
           ]),
         {:ok, decoded} <- Jason.decode(raw),
         [prediction | _] <- decoded["predictions"],
         score when is_number(score) <- prediction["fraud_score"] do
      {:ok, score}
    else
      error ->
        IO.inspect(error, label: "Vertex error")
        {:error, :vertex_failed}
    end
  end
end
