defmodule ChatWeb.TestLive do
  use Phoenix.LiveView

  # def render(assigns) do
  #   ~L"""
  #     <div></div>
  #   """
  # end

  def mount(_, _, socket) do
    {:ok, socket}
  end
end
