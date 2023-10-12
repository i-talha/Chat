defmodule Chat.KeyManager do
  use GenServer

  require Logger

  @spec insert_key(String.t(), String.t()) :: :ok

  def insert_key(key, value) do
    GenServer.cast(__MODULE__, {:insert_room_key, key, value})
    insert_public_room(key)
  end

  @spec get_key(String.t()) :: list()

  def get_key(key) do
    GenServer.call(__MODULE__, {:get_room_key, key})
  end

  def insert_public_room(key) do
    GenServer.cast(__MODULE__, {:insert_public_room, key})
  end

  def all_public_room() do
    GenServer.call(__MODULE__, :all_public_room)
  end

  @spec init(any()) :: {:ok, map()}

  def init(_arg) do
    :ets.new(:key_manager, [:set, :public, :named_table])
    {:ok, Map.new() |> Map.put(:rooms, [])}
  end

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def handle_cast({:insert_room_key, key, value}, state) do
    true = :ets.insert(:key_manager, {key, value})
    {:noreply, state}
  end

  def handle_cast({:insert_public_room, key}, state) do
    {:noreply, Map.put(state, :rooms, state.rooms ++ [key])}
  end

  def handle_call({:get_room_key, key}, _from, state) do
    actual_key = :ets.lookup(:key_manager, key)
    {:reply, actual_key, state}
  end

  def handle_call(:all_public_room, _from, state) do
    {:reply, Map.get(state, :rooms), state}
  end
end
