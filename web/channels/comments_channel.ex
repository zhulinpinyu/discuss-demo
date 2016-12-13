defmodule Discuss.CommentsChannel do
  use Discuss.Web, :channel

  def join(name, _params, socket) do
    IO.puts "+++++++++++++++++++++++++++"
    IO.puts name
    IO.puts "+++++++++++++++++++++++++++"
    {:ok, %{hey: "#{name}, Welcome back..."}, socket}
  end

  def handle_in(name, message, socket) do
    {:reply, :ok, socket}
  end
end
