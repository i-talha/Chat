defmodule Chat.Authenticator do
  require Logger
  alias Phoenix.Token
  alias Chat.KeyManager

  @logger_prefix "ERROR FROM #{__MODULE__} :: "

  @spec generate_key(String.t()) :: String.t()

  def generate_key(room_name) do
    payload = %{
      room: room_name,
      status: :ok
    }

    long_key = Token.sign(ChatWeb.Endpoint, do_get_key(), payload)
    short_key = :crypto.hash(:sha256, long_key) |> Base.encode16() |> String.slice(0..7)

    :ok = KeyManager.insert_key(short_key, long_key)

    short_key
  end

  @spec verify_room(String.t()) :: {:ok, String.t()} | {:error, String.t()}

  def verify_room(key) when is_binary(key) do
    with [{^key, actual_key}] <- KeyManager.get_key(key),
         {:ok, %{status: :ok, room: room_name}} <-
           Token.verify(ChatWeb.Endpoint, do_get_key(), actual_key) do
      {:ok, room_name}
    else
      {:error, msg} = error ->
        Logger.error("#{@logger_prefix}#{msg}")
        error

      [] ->
        msg = "INVALID ROOM KEY"
        Logger.error("#{@logger_prefix}#{msg}")
        {:error, msg}
    end
  end

  defp do_get_key(), do: Application.get_env(:chat, :secret)
end
