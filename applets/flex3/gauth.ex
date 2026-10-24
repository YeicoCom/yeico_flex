defmodule Flex.Gauth do
  use Terminal.Live

  @dbname :gauth_cubdb

  def db_init() do
    case Process.whereis(@dbname) do
      pid when is_pid(pid) ->
        :nop

      nil ->
        {:ok, _} = CubDB.start_link(data_dir: Terminal.dpath("@home/#{@dbname}"), name: @dbname)
    end
  end

  def db_put(guser) do
    CubDB.put_new(@dbname, guser, %{stamp: NaiveDateTime.utc_now()})
  end

  def db_del(guser) do
    CubDB.delete(@dbname, guser)
  end

  def db_get(guser) do
    CubDB.get(@dbname, guser)
  end

  def db_list() do
    CubDB.select(@dbname) |> Enum.to_list()
  end

  def client_id() do
    Api.path()
    |> Path.join("secret/gauth.json")
    |> File.read!()
    |> Jason.decode!()
    |> Map.get("client_id")
  end

  def push_login(socket, referer, client_id, %{"credential" => credential}) do
    url = "https://oauth2.googleapis.com/tokeninfo?id_token=#{credential}"
    %{"email" => email, "aud" => ^client_id} = Req.get!(url).body
    push_event(socket, "gauth:href", %{href: login_url(referer, email)})
  end

  def login_url(referer, email) do
    expiry = NaiveDateTime.shift(NaiveDateTime.utc_now(), second: 5)
    put = %{key: "guser", value: %{email: email}, expiry: expiry, redirect: referer}
    token = Terminal.encode(put)
    query = URI.encode_query(%{token: token})
    "/put?#{query}"
  end

  def push_logout(socket) do
    push_event(socket, "gauth:href", %{href: logout_url()})
  end

  def logout_url(path \\ "/") do
    expiry = NaiveDateTime.shift(NaiveDateTime.utc_now(), year: 1_000)
    token = Terminal.encode(%{key: "guser", expiry: expiry, redirect: path})
    query = URI.encode_query(%{token: token})
    "/del?#{query}"
  end

  def get_spec(:any), do: %{check: &check_any/1, key: :guser}
  def get_spec(:db), do: %{check: &check_db/1, key: :guser}

  defp check_any({path, query, guser}) do
    with %{email: _} <- guser do
      nil
    else
      _ ->
        to = Base.encode16(if(query, do: "#{path}?#{query}", else: path))
        "/login?to=#{to}"
    end
  end

  defp check_db({path, query, guser}) do
    with %{email: email} <- guser,
         %{stamp: _} <- db_get(email) do
      nil
    else
      _ ->
        to = Base.encode16(if(query, do: "#{path}?#{query}", else: path))
        "/login?to=#{to}"
    end
  end
end
