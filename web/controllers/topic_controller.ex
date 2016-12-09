defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  alias Discuss.Topic

  def new(conn, params) do
    changeset = Topic.changeset(%Topic{}, %{})
    render conn, "new.html", changeset: changeset
  end

  def create(conn, params) do
    IO.puts "++++++++++++++++++++++++++++++++++++"
    IO.inspect params["topic"]
    %{"topic" => topic} = params
    IO.inspect topic
    IO.puts "++++++++++++++++++++++++++++++++++++"
  end
end
