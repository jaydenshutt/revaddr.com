defmodule Revaddr.Reverse do
  @moduledoc """
  Reverse-geocode a single lat/lon with the RevAddr HTTP API.

  ## Run

      export REVADDR_API_KEY=sk_live_...
      mix deps.get
      mix run -e "Revaddr.Reverse.main([])"
      mix run -e "Revaddr.Reverse.main([\\"37.7749\\", \\"-122.4194\\"])"

  Uses Erlang `:httpc` plus Jason. Suitable for Phoenix controllers or Oban jobs.
  """

  @default_base "https://api.revaddr.com"

  @doc """
  GET /v1/reverse and return the inner `"result"` map.
  """
  def reverse(lat, lon, api_key, base_url \\ @default_base)
      when is_number(lat) and is_number(lon) and is_binary(api_key) do
    base = String.trim_trailing(base_url, "/")
    # URI.encode_query builds lat/lon query string.
    query = URI.encode_query(%{"lat" => lat, "lon" => lon})
    url = String.to_charlist("#{base}/v1/reverse?#{query}")

    headers = [
      {~c"x-api-key", String.to_charlist(api_key)},
      {~c"Accept", ~c"application/json"}
    ]

    # inets httpc: ensure started in mix run / releases.
    :inets.start()
    :ssl.start()

    request = {url, headers}

    case :httpc.request(:get, request, [timeout: 30_000], body_format: :binary) do
      {:ok, {{_, status, _}, _headers, body}} when status >= 200 and status < 300 ->
        case Jason.decode(body) do
          {:ok, %{"result" => result}} when is_map(result) -> {:ok, result}
          {:ok, _} -> {:error, :missing_result}
          {:error, err} -> {:error, err}
        end

      {:ok, {{_, status, _}, _, body}} ->
        {:error, {:http, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  def main(args) do
    api_key = System.get_env("REVADDR_API_KEY") |> to_string() |> String.trim()

    if api_key == "" do
      IO.puts(:stderr, "Set REVADDR_API_KEY to your RevAddr API key.")
      System.halt(1)
    end

    base =
      case System.get_env("REVADDR_BASE_URL") do
        nil -> @default_base
        "" -> @default_base
        v -> v
      end

    # Website hero default: White House.
    {lat, lon} =
      case args do
        [a, b | _] -> {String.to_float(a), String.to_float(b)}
        _ -> {38.8977, -77.0365}
      end

    case reverse(lat, lon, api_key, base) do
      {:ok, result} ->
        IO.puts(Map.get(result, "formatted_address") || "(no formatted_address)")
        IO.puts(Jason.encode!(result, pretty: true))

      {:error, reason} ->
        IO.puts(:stderr, inspect(reason))
        System.halt(1)
    end
  end
end
