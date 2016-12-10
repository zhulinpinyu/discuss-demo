### Phoenix 框架学习记录
@(Elixir)[phoenix, elixir]

**自定义controller使用phoenix框架的controller 作用有点类似于继承. 对应的文件是`web.ex`**

```elixir
defmodule Discuss.TopicController do
  use Discuss.Web, :controller
  ...
end
```
---

**打印输出：**
```elixir
#输出文本
IO.puts "Phoenix"

#输出struct(conn是struct结构)
IO.inspect conn
```
---

**controller中action 的参数conn**

```elixir
IO.inspect conn
```
输出：

```plain
[debug] Processing by Discuss.TopicController.new/2
  Parameters: %{}
  Pipelines: [:browser]
%Plug.Conn{adapter: {Plug.Adapters.Cowboy.Conn, :...}, assigns: %{},
 before_send: [#Function<0.7834419/1 in Plug.CSRFProtection.call/2>,
  #Function<4.1852342/1 in Phoenix.Controller.fetch_flash/2>,
  #Function<0.46198565/1 in Plug.Session.before_send/2>,
  #Function<1.5096610/1 in Plug.Logger.call/2>,
  #Function<0.27163530/1 in Phoenix.LiveReloader.before_send_inject_reloader/2>],
 body_params: %{}, cookies: %{}, halted: false, host: "localhost",
 method: "GET", owner: #PID<0.416.0>, params: %{}, path_info: ["topics", "new"],
 path_params: %{}, peer: {{127, 0, 0, 1}, 49539}, port: 4000,
 private: %{Discuss.Router => {[], %{}}, :phoenix_action => :new,
   :phoenix_controller => Discuss.TopicController,
   :phoenix_endpoint => Discuss.Endpoint, :phoenix_flash => %{},
   :phoenix_format => "html", :phoenix_layout => {Discuss.LayoutView, :app},
   :phoenix_pipelines => [:browser],
   :phoenix_route => #Function<1.23482846/1 in Discuss.Router.match_route/4>,
   :phoenix_router => Discuss.Router, :phoenix_view => Discuss.TopicView,
   :plug_session => %{}, :plug_session_fetch => :done}, query_params: %{},
 query_string: "", remote_ip: {127, 0, 0, 1}, req_cookies: %{},
 req_headers: [{"host", "localhost:4000"}, {"connection", "keep-alive"},
  {"cache-control", "max-age=0"}, {"upgrade-insecure-requests", "1"},
  {"user-agent",
   "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/57.0.2943.0 Safari/537.36"},
  {"accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8"},
  {"accept-encoding", "gzip, deflate, sdch, br"},
  {"accept-language", "en-US,en;q=0.8,zh-CN;q=0.6,zh;q=0.4"}],
 request_path: "/topics/new", resp_body: nil, resp_cookies: %{},
 resp_headers: [{"cache-control", "max-age=0, private, must-revalidate"},
  {"x-request-id", "97bfbf24h3fep1m2l77d46comeup95fa"},
  {"x-frame-options", "SAMEORIGIN"}, {"x-xss-protection", "1; mode=block"},
  {"x-content-type-options", "nosniff"}], scheme: :http, script_name: [],
 secret_key_base: "xs4o//HoiTFQMf+yJR5Q/VtgGpRWewGKNnFE6nzJ9+XeUEwbA0YXo2FwAZ/0f1qG",
 state: :unset, status: nil}
```
---

**添加model**

```elixir
defmodule Discuss.Topic do
  use Discuss.Web, :model

  #数据库中的表：topics
  schema "topics" do
    field :title, :string
  end
end
```
---

**在model中进行数据校验**

```elixir
def changeset(struct, params \\%{}) do
  struct
  |> cast(params,[:title])
  |> validate_required([:title])
end
```
原理详解：

![Alt text](http://ww2.sinaimg.cn/large/620e854dgw1fali7vlbiyj20bk09dwfd.jpg)


CLI test Model `changeset`

```elixir
iex(1)> struct = %Discuss.Topic{}
#%Discuss.Topic{__meta__: #Ecto.Schema.Metadata<:built, "topics">, id: nil, title: nil}

iex(2)> params = %{title: "JS Elixir"}
#%{title: "JS Elixir"}

iex(3)> Discuss.Topic.changeset(struct,params)
#Ecto.Changeset<action: nil, changes: %{title: "JS Elixir"}, errors: [], data: #Discuss.Topic<>, valid?: true>


iex(4)> Discuss.Topic.changeset(struct,%{})
#Ecto.Changeset<action: nil, changes: %{}, errors: [title: {"can't be blank", []}], data: #Discuss.Topic<>, valid?: false>
```
params 为`%{}`时：
`errors: [title: {"can't be blank", []}]`

---

**添加视图**

首先创建views: `views/topic_view.ex`

```elixir
defmodule Discuss.TopicView do
  use Discuss.Web, :view
end
```

接着创建templates: `templates/topic/new.html.eex`

```elixir
<%= form_for @changeset,topic_path(@conn, :create), fn f -> %>
  <div class="form-group">
    <%= text_input f, :title, placeholder: "Title", class: "form-control" %>
  </div>
  <%= submit "Save", class: "btn btn-primary" %>
<% end %>
```

当前的controller: `controllers/topic_controller.ex`

```elixir
defmodule Discuss.TopicController do
  use Discuss.Web, :controller

  alias Discuss.Topic

  def new(conn, params) do
    changeset = Topic.changeset(%Topic{}, %{})
    render conn, "new.html", changeset: changeset
  end
end
```

对应的`router.ex`

```elixir
...
  scope "/", Discuss do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/topics/new", TopicController, :new
    post "/topics", TopicController, :create
  end
...
```
 ---
**查看当前的route**

```bash
mix phoenix.routes
```

输出结果：

```plain
page_path  GET   /            Discuss.PageController :index
topic_path  GET   /topics/new  Discuss.TopicController :new
topic_path  POST  /topics      Discuss.TopicController :create
```

---

**处理来自form 提交**

```elixir
def create(conn, %{"topic" => topic}) do
  changeset = Topic.changeset(%Topic{},topic)
  case Repo.insert(changeset) do
      {:ok, post} ->
	      conn
          |> put_flash(:info, "Topic Created") #flash info
          |> redirect(to: topic_path(conn, :index))#redirect to index page
      {:error, changeset} ->
          render conn, "new.html", changeset: changeset
  end
end
```

new.html 添加如下代码：

```elixir
<%= error_tag f, :title %>
```

---

**重点：查询所有topic 数据**

```elixir
topics = Repo.all(Discuss.Topic)
```

打印输出：
```plain
[debug] QUERY OK source="topics" db=1.5ms decode=4.3ms
SELECT t0."id", t0."title" FROM "topics" AS t0 []
[%Discuss.Topic{__meta__: #Ecto.Schema.Metadata<:loaded, "topics">, id: 1,
  title: "zzz"}]
```
---

**循环输出：**

```elixir
<ul class="collection">
  <%= for topic <- @topics do %>
    <li class="collection-item">
      <%= topic.title %>
    </li>
  <% end %>
</ul>
```

---

**edit action的实现**

```elixir
def edit(conn, %{"id" => topic_id}) do
  topic = Repo.get(Topic,topic_id)
  changeset = Topic.changeset(topic)
  render conn, "edit.html", changeset: changeset, topic: topic
end
```

**重点关注**：`topic = Repo.get(Topic,topic_id)`通过topic_id,在数据库中查询对应的topic

---

**完整的update action**

```elixir
def update(conn, %{"id" => topic_id, "topic" => topic}) do
  old_topic = Repo.get(Topic, topic_id) #获取原有的topic
  changeset = Topic.changeset(old_topic, topic) #构建changeset
  case Repo.update(changeset) do #利用changeset更新数据
    {:ok, _topic} ->
      conn
      |> put_flash(:info, "Topic Updated")
      |> redirect(to: topic_path(conn, :index))
    {:error, changeset} ->
      render conn, "edit.html", changeset: changeset, topic: old_topic
  end
end
```
---

**更新router 配置方式**

原来的配置：

```elixir
get "/", TopicController, :index
get "/topics/new", TopicController, :new
post "/topics", TopicController, :create
get "/topics/:id/edit", TopicController, :edit
put "/topics/:id", TopicController, :update
```

新的配置(将覆盖所有topic 的action)：

```elixir
resources "/", TopicController
```

运行命令`mix phoenix.routes`查看

```elixir
topic_path  GET     /          Discuss.TopicController :index
topic_path  GET     /:id/edit  Discuss.TopicController :edit
topic_path  GET     /new       Discuss.TopicController :new
topic_path  GET     /:id       Discuss.TopicController :show
topic_path  POST    /          Discuss.TopicController :create
topic_path  PATCH   /:id       Discuss.TopicController :update
            PUT     /:id       Discuss.TopicController :update
topic_path  DELETE  /:id       Discuss.TopicController :delete
```

另外：也可`resources "/topics", TopicController`  那么根路径`/`就没有了。

---

**delete action 的实现（注意叹号）**

```elixir
def delete(conn, %{"id" => topic_id}) do
  Repo.get!(Topic, topic_id)
  |> Repo.delete!

  conn
  |> put_flash(:info, "Delete Topic")
  |> redirect(to: topic_path(conn, :index))
end
```
https://hexdocs.pm/ecto/Ecto.Repo.html#c:get!/3
https://hexdocs.pm/ecto/Ecto.Repo.html#c:delete!/2

---
