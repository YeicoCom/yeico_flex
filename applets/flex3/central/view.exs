defmodule Central.View do
  use Terminal.Live

  defp render(assigns) do
    ~H"""
    <div id="main_view" class="flex flex-col h-full w-full gap-4 p-16 overflow-y-auto" phx-window-keydown="escape" phx-key="Escape">
      <div class="flex gap-2 justify-center items-center">
        <div class="text-3xl">Central</div>
        <div class="grow"/>
        <a href={Flex.Gauth.logout_url()} title={@guser.email} class="daisy-link daisy-link-hover hover:text-warning">Logout</a>
      </div>
      <div class="flex flex-col gap-2 font-mono">
        <div :for={{host, %{stamp: stamp, name: name, build: build}} <- @slaves} class="flex flex-col gap-1">
            <div class={[@selected==host && "bg-neutral rounded", "flex p-1 items-center justify-between"]}>
              <div class="flex gap-2 daisy-link daisy-link-hover"
                phx-click="select" phx-value-host={host}
                title={build}>
                <div>{stamp |> NaiveDateTime.truncate(:second)}</div>
                <div>{host}</div>
                <div>{name}</div>
              </div>
              <div :if={@selected == host} class="flex gap-2">
                <a href={"/shell?host=#{host}"} target="_blank" class="daisy-link daisy-link-hover hover:text-primary">Shell</a>
                <div class="daisy-link daisy-link-hover hover:text-warning" phx-click="reboot" phx-value-host={host}>Reboot</div>
              </div>
            </div>
            <form :if={@selected == host} id="config_form" phx-hook="Form" class="grid grid-cols-[200px_1fr] gap-2 p-1" phx-change="input:change" phx-submit="input:save">
              <div>Device Name</div>
              <input name="name" type="text" autocomplete="off"
                id="config_name" phx-hook="Focus"
                class="grow daisy-input daisy-input-bordered"
                value={@input[:name]}/>
              <div>Owner Email</div>
              <input name="owner" type="email" autocomplete="off"
                class="grow daisy-input daisy-input-bordered"
                value={@input[:owner]}/>
              <div>Admin Password</div>
              <input name="pass" type="password" autocomplete="off"
                class="grow daisy-input daisy-input-bordered"
                value={@input[:pass]}/>
              <div>Public Keys</div>
              <textarea name="keys" autocomplete="off"
                class="grow daisy-textarea daisy-textarea-bordered resize-y overflow-x-auto whitespace-nowrap" rows="4s"
              >{@input[:keys]}</textarea>
              <div>Master Endpoint</div>
              <input name="master" type="text" autocomplete="off"
                class="grow daisy-input daisy-input-bordered"
                value={@input[:master]}/>
              <div>Wireguard Config</div>
              <textarea name="wire" autocomplete="off"
                class="grow daisy-textarea daisy-textarea-bordered resize-y overflow-x-auto whitespace-nowrap" rows="8"
              >{@input[:wire]}</textarea>
              <div/>
              <button type="submit" class="py-4 daisy-btn daisy-btn-outline">Save</button>
            </form>
        </div>
      </div>
    </div>
    """
  end

  def handler(_path, props, admin) do
    fn
      {:mount, socket = %{assigns: assigns}, state} ->
        applet = props[:applet_name] || "flex3"
        socket = assign(socket, applet_css: props[:applet_css] || "/applets/#{applet}.css")
        socket = assign(socket, applet_js: props[:applet_js] || "/applets/#{applet}.js")
        socket = assign(socket, page_suffix: props[:page_suffix] || " · Flex")
        socket = assign(socket, page_title: props[:page_title] || "Central")
        socket = assign(socket, applet_args: props[:applet_args])
        state = Map.put(state, :connected?, assigns.connected?)
        state = Map.put(state, :guser, assigns.session["guser"])
        state = Map.put(state, :selected, nil)
        state = Map.put(state, :input, %{})
        {socket, state}

      {:render, _assigns, state} ->
        render(state)

      {:params, socket, state = %{guser: %{email: email}, connected?: connected?}, _params, _uri} ->
        # nice place for after connect initialization
        if connected? and email == admin, do: Terminal.Publish.subscribe!({:slave, :owner, nil})
        if connected?, do: Terminal.Publish.subscribe!({:slave, :owner, email})
        state = Map.put(state, :slaves, Central.Utils.slaves(admin, email))
        {socket, state}

      {:event, socket, state, "reboot", %{"host" => host}} ->
        # confirmed to work on qemu x86 image
        Api.async(fn -> Terminal.run(host, ":os.cmd('reboot')") end)
        {socket, state}

      {:event, socket, state = %{slaves: slaves}, "select", %{"host" => host}} ->
        {_, %{name: name, pass: pass, keys: keys, wire: wire, owner: owner, master: master}} =
          Enum.find(slaves, fn {k, _} -> k == host end)

        state = put_in(state, [:input, :name], name)
        state = put_in(state, [:input, :pass], pass)
        state = put_in(state, [:input, :keys], keys)
        state = put_in(state, [:input, :wire], wire)
        state = put_in(state, [:input, :owner], owner)
        state = put_in(state, [:input, :master], master)
        state = Map.put(state, :selected, host)
        {socket, state}

      {:event, socket, state, "input:change", params = %{"_target" => [target]}} ->
        state = put_in(state, [:input, String.to_atom(target)], params[target])
        {socket, state}

      {:event, socket, state = %{selected: selected}, "input:save",
       %{
         "name" => name,
         "pass" => pass,
         "keys" => keys,
         "wire" => wire,
         "owner" => owner,
         "master" => master
       }} ->
        # wg starts as nop server on empty config file
        Log.debug(
          host: selected,
          name: name,
          pass: pass,
          keys: keys,
          wire: wire,
          owner: owner,
          master: master
        )

        # spawn because touching any config file kills the slave connection
        cmd =
          """
            spawn(fn ->
              Terminal.uconfig!("name", Base.decode16!("#{name |> Base.encode16()}"))
              Terminal.uconfig!("pass", Base.decode16!("#{pass |> Base.encode16()}"))
              Terminal.uconfig!("keys", Base.decode16!("#{keys |> Base.encode16()}"))
              Terminal.uconfig!("wire", Base.decode16!("#{wire |> Base.encode16()}"))
              Terminal.uconfig!("owner", Base.decode16!("#{owner |> Base.encode16()}"))
              Terminal.uconfig!("master", Base.decode16!("#{master |> Base.encode16()}"))
              Terminal.sync()
            end)
          """

        Api.async(fn ->
          Terminal.run(selected, cmd)
          Terminal.drop(selected)
        end)

        state = Map.put(state, :selected, nil)
        {socket, state}

      {:event, socket, state, "escape", _} ->
        state = Map.put(state, :selected, nil)
        {socket, state}

      {:event, socket, state, _event, _params} ->
        {socket, state}

      {:info, socket, state = %{guser: %{email: ^admin}}, {{:slave, :owner, nil}, _, _}} ->
        state = Map.put(state, :slaves, Central.Utils.slaves(admin, admin))
        {socket, state}

      {:info, socket, state = %{guser: %{email: email}}, {{:slave, :owner, email}, _, _}} ->
        state = Map.put(state, :slaves, Central.Utils.slaves(admin, email))
        {socket, state}

      {:info, socket, state, _event} ->
        {socket, state}

      {:close, _socket, _state, _reason} ->
        :ok
    end
  end
end

Terminal.view(path, Central.View.handler(path, props, admin), auth: auth)
