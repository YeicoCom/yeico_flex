defmodule Wire.View do
  use Terminal.Live

  defp render(assigns) do
    ~H"""
    <div id="main_view" phx-hook="Copy" class="flex flex-col h-screen gap-2 p-4 select-none bg-base-300 text-base-content"
      inert={!!@modal} phx-window-keydown="modal:close" phx-key="Escape">
      <div class="flex items-center gap-2">
        <div class="text-4xl font-bold">Wire</div>
        <div class="grow"/>
        <a href={Flex.Gauth.logout_url()} title={@guser.email} class="daisy-link daisy-link-hover">Logout</a>
      </div>
      <div class="grow flex gap-2 overflow-hidden">
        <div class="flex flex-col gap-2 bg-base-200 rounded py-4 w-[24em]">
          <div class="flex items-center justify-between px-4">
            <div class="text-2xl font-bold">Networks</div>
            <div class="daisy-btn daisy-btn-ghost daisy-btn-sm" phx-click="network:add" title="Add Network">
              <span class="hero-plus"/>
            </div>
          </div>
          <div class="grow flex flex-col gap-1 overflow-y-auto">
            <div :for={{nid, net} <- @nets} class="flex gap-2 items-center hover:bg-base-300 cursor-pointer px-4 py-1"
              phx-click="network:select" phx-value-nid={nid} title="Select Network">
              <div class={[
                (@error[nid][:error?] == nil) && "hero-question-mark-circle",
                (@error[nid][:error?] == false) && "hero-check text-success",
                (@error[nid][:error?] == true) && "hero-exclamation-circle text-warning",
                (@error[nid][:error?] == :failed) && "hero-exclamation-triangle text-warning",
              ]} title={@error[nid][:error]}/>
              <div>{net.name} {net.prefix} {net.port} {net.status}</div>
            </div>
          </div>
        </div>
        <div :if={@nid} id="net_view" class="grow flex flex-col bg-base-200 rounded py-4 gap-4">
          <div class="px-4 flex gap-2 items-center text-2xl font-bold hover:bg-base-300 cursor-pointer"
            phx-click="network:edit" phx-value-nid={@nid} title="Edit Network">
            <div class={[
              (@error[@nid][:error?] == nil) && "hero-question-mark-circle",
              (@error[@nid][:error?] == false) && "hero-check text-success",
              (@error[@nid][:error?] == true) && "hero-exclamation-circle text-warning",
              (@error[@nid][:error?] == :failed) && "hero-exclamation-triangle text-warning",
            ]} title={@error[@nid][:error]}/>
            <div>{@net.name} {@net.prefix} {@net.port} {@net.status}</div>
            <div class="hero-document-duplicate" title="Copy Enabled Hosts" phx-click="net:hosts"/>
          </div>
          <div class="px-4 text-2xl flex items-center justify-between">
            <div class="font-bold">Nodes</div>
            <div class="daisy-btn daisy-btn-ghost daisy-btn-sm" phx-click="node:add" title="Add Node">
              <span class="hero-plus"/>
            </div>
          </div>
          <div class="grow flex flex-col gap-1 overflow-hidden">
            <div class="px-4 grid grid-cols-[3em_8em_4em_1fr_1fr_1fr_9em]">
              <div/>
              <div>Name</div>
              <div>Suffix</div>
              <div>Exports</div>
              <div>Imports</div>
              <div>Status</div>
              <div>Actions</div>
            </div>
            <div class="grow flex flex-col gap-1 overflow-y-auto">
              <div :for={{index, n} <- @nodes} class="px-4 grid grid-cols-[3em_8em_4em_1fr_1fr_1fr_9em] hover:bg-base-300 cursor-pointer"
                  phx-click="node:edit" phx-value-index={index} title="Edit Node">
                <div class={[
                    (@error[@nid][:nodes][index][:error?] == nil) && "hero-question-mark-circle",
                    (@error[@nid][:nodes][index][:error?] == false) && "hero-check text-success",
                    (@error[@nid][:nodes][index][:error?] == true) && "hero-exclamation-circle text-warning",
                  ]} title={@error[@nid][:nodes][index][:error]}/>
                <div>{n.name}</div>
                <div>{n.suffix}</div>
                <div>{n.exports}</div>
                <div>{n.imports}</div>
                <div>{n.status} {@status[n.pub]}</div>
                <div class="flex gap-2">
                    <div class="hero-document-duplicate" title="Copy Conf" phx-click="node:conf" phx-value-index={index}/>
                    <div class="hero-document-duplicate" title="Copy Yaml" phx-click="node:yaml" phx-value-index={index}/>
                    <div class="hero-document-duplicate" title="Copy Proxy" phx-click="node:proxy" phx-value-index={index}/>
                    <div class="hero-arrow-path" title="Reset Peer" phx-click="node:reset" phx-value-index={index}/>
                    <div class="hero-arrow-path" title="Regenerate Keys" phx-click="node:regen" phx-value-index={index}/>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <.fui fun={&Flex.Modal.render/1} :if={@modal[:type] == :network}
      title={@modal[:title]} class="min-w-[360px] flex flex-col gap-4">
        <form id="modal_form" phx-submit="network:save" class="pt-4 flex flex-col gap-4"
          phx-hook="Form" phx-update="ignore" autocomplete="off">
          <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
            <input type="hidden" name="nid" value={@modal[:nid]}>
            <div>Name</div>
            <input type="text" name="name" value={@modal[:net][:name]} type="text" required id="modal_autofocus" phx-hook="Focus"
              class="daisy-input daisy-input-bordered"/>
            <div>Prefix</div>
            <input type="text" name="prefix" value={@modal[:net][:prefix]} type="text" required
              class="daisy-input daisy-input-bordered"/>
            <div>Port</div>
            <input type="text" name="port" value={@modal[:net][:port]} type="number" step="1" min="1" max="65535" required
              class="daisy-input daisy-input-bordered"/>
            <div>Status</div>
            <select name="status" required class="daisy-select daisy-select-bordered">
              <option :for={value <- ["Enabled", "Disabled"]} value={value}
              selected={value == @modal[:net][:status]} title={value}>{value}</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-2 items-center">
            <div phx-click="network:delete" phx-value-nid={@modal[:nid]}
              class="daisy-link daisy-link-hover hover:text-warning">Delete</div>
            <button type="submit" class="daisy-btn daisy-btn-outline">Accept</button>
          </div>
        </form>
    </.fui>
    <.fui fun={&Flex.Modal.render/1} :if={@modal[:type] == :node}
      title={@modal[:title]} class="min-w-[360px] flex flex-col gap-4">
        <form id="modal_form" phx-submit="node:save" class="pt-4 flex flex-col gap-4"
          phx-hook="Form" phx-update="ignore" autocomplete="off">
          <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
            <input type="hidden" name="index" value={@modal[:index]}>
            <div>Name</div>
            <input type="text" name="name" value={@modal[:node][:name]} type="text" required id="modal_autofocus" phx-hook="Focus"
              class="daisy-input daisy-input-bordered"/>
            <div>Suffix</div>
            <input type="text" name="suffix" value={@modal[:node][:suffix]} type="text" required
              class="daisy-input daisy-input-bordered"/>
            <div>Exports</div>
            <input type="text" name="exports" value={@modal[:node][:exports]} type="text"
              class="daisy-input daisy-input-bordered"/>
            <div>Imports</div>
            <input type="text" name="imports" value={@modal[:node][:imports]} type="text"
              class="daisy-input daisy-input-bordered"/>
            <div>Status</div>
            <select name="status" required class="daisy-select daisy-select-bordered">
              <option :for={value <- ["Enabled", "Disabled"]} value={value}
              selected={value == @modal[:node][:status]} title={value}>{value}</option>
            </select>
          </div>
          <div class="grid grid-cols-2 gap-2 items-center">
            <div>
            <div phx-click="node:delete" phx-value-index={@modal[:index]}
              class="daisy-link daisy-link-hover hover:text-warning">Delete</div>
            </div>
            <button type="submit" class="daisy-btn daisy-btn-outline">Accept</button>
          </div>
        </form>
    </.fui>
    """
  end

  def handler(_path, props) do
    fn
      {:mount, socket = %{assigns: %{session: session, tzoffset: tzoffset}}, state} ->
        applet = props[:applet_name] || "flex3"
        socket = assign(socket, applet_css: props[:applet_css] || "/applets/#{applet}.css")
        socket = assign(socket, applet_js: props[:applet_js] || "/applets/#{applet}.js")
        socket = assign(socket, page_suffix: props[:page_suffix] || " · Flex")
        socket = assign(socket, page_title: props[:page_title] || "Wire")
        socket = assign(socket, applet_args: props[:applet_args])
        state = Map.put(state, :guser, session["guser"])
        state = Map.put(state, :tzoffset, tzoffset)
        state = Map.put(state, :status, Api.subget!("wire:status"))
        state = Map.put(state, :error, Api.subget!("wire:error"))
        state = Map.put(state, :nets, Wire.Store.list())
        state = Map.put(state, :modal, nil)
        state = Map.put(state, :net, nil)
        state = Map.put(state, :nid, nil)
        {socket, state}

      {:params, socket, state, _params, _uri} ->
        {socket, state}

      {:render, _assigns, state = %{nets: nets, net: net}} ->
        nets = Enum.sort_by(nets, fn {_, %{name: name}} -> name end)
        state = Map.put(state, :nets, nets)
        nodes = net[:nodes] || %{}
        sorter = fn {_, %{suffix: su, name: na}} -> {String.to_integer(su), na} end
        nodes = Enum.sort_by(nodes, sorter)
        state = Map.put(state, :nodes, nodes)
        render(state)

      {:event, socket, state, "modal:close", _params} ->
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state, "network:add", _params} ->
        state = Map.put(state, :modal, %{type: :network, title: "Add Network"})
        {socket, state}

      {:event, socket, state = %{nets: nets}, "network:edit", %{"nid" => nid}} ->
        state = %{net: net} = Map.put(state, :net, nets[nid])
        state = Map.put(state, :nid, nid)

        state =
          Map.put(state, :modal, %{
            type: :network,
            title: "Edit Network",
            nid: nid,
            net: net
          })

        {socket, state}

      {:event, socket, state = %{net: net, nets: nets}, "network:save",
       %{
         "nid" => nid,
         "name" => name,
         "prefix" => prefix,
         "port" => port,
         "status" => status
       }} ->
        name = String.trim(name)
        prefix = String.trim(prefix)
        port = String.trim(port)
        status = String.trim(status)
        {nid, net} = if(nid == "", do: Wire.Store.def(), else: {nid, net})
        net = Map.merge(net, %{name: name, prefix: prefix, port: port, status: status})
        {nid, net} = Wire.Store.save(:net, nid, net)
        state = Map.put(state, :nets, Map.put(nets, nid, net))
        state = Map.put(state, :net, net)
        state = Map.put(state, :nid, nid)
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{nets: nets}, "network:select", %{"nid" => nid}} ->
        state = Map.put(state, :net, nets[nid])
        state = Map.put(state, :nid, nid)
        {socket, state}

      {:event, socket, state = %{nets: nets}, "network:delete", %{"nid" => nid}} ->
        :ok = Wire.Store.delete(:net, nid)
        state = Map.put(state, :nets, Map.delete(nets, nid))
        state = Map.put(state, :net, nil)
        state = Map.put(state, :nid, nil)
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state, "node:add", _params} ->
        state = Map.put(state, :modal, %{type: :node, title: "Add Node"})
        {socket, state}

      {:event, socket, state = %{net: net}, "node:edit", %{"index" => index}} ->
        node = net.nodes[index]

        state =
          Map.put(state, :modal, %{type: :node, title: "Edit Node", index: index, node: node})

        {socket, state}

      {:event, socket, state = %{nid: nid, net: net, nets: nets}, "node:save",
       %{
         "index" => index,
         "name" => name,
         "suffix" => suffix,
         "imports" => imports,
         "exports" => exports,
         "status" => status
       }} ->
        name = String.trim(name)
        suffix = String.trim(suffix)
        imports = String.trim(imports)
        exports = String.trim(exports)
        status = String.trim(status)
        node = %{name: name, suffix: suffix, imports: imports, exports: exports, status: status}
        net = put_in(net, [:nodes, index], node)
        {^nid, net} = Wire.Store.save(:net, nid, net)
        state = Map.put(state, :nets, Map.put(nets, nid, net))
        state = Map.put(state, :net, net)
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{nid: nid, net: net, nets: nets}, "node:delete",
       %{"index" => index}} ->
        {_, net} = pop_in(net, [:nodes, index])
        {^nid, net} = Wire.Store.save(:net, nid, net)
        state = Map.put(state, :nets, Map.put(nets, nid, net))
        state = Map.put(state, :net, net)
        state = Map.put(state, :modal, nil)
        {socket, state}

      {:event, socket, state = %{net: net}, "net:hosts", _params} ->
        socket = push_event(socket, "copy:text", %{text: Wire.Template.hosts(net)})
        {socket, state}

      {:event, socket, state = %{net: net}, "node:conf", %{"index" => index}} ->
        socket = push_event(socket, "copy:text", %{text: Wire.Template.node(net, index)})
        {socket, state}

      {:event, socket, state = %{net: net}, "node:yaml", %{"index" => index}} ->
        socket = push_event(socket, "copy:text", %{text: Wire.Template.yaml(net, index)})
        {socket, state}

      {:event, socket, state = %{net: net}, "node:proxy", %{"index" => index}} ->
        # generate from bash if special expiration needed
        deathline = System.system_time(:second) + 60 * 5
        ip = Wire.Template.ip(net, index)
        content = "#{ip}\n#{deathline}"
        token = UUID.uuid1()
        dir = Terminal.dpath("/var/run/wire-nginx-proxy")
        write = fn -> Path.join(dir, token) |> File.write!(content) end
        chown = fn -> System.shell("chmod -R www-data:www-data #{dir}") end
        Applet.Utils.safe(write)
        Applet.Utils.safe(chown)
        hostname = Api.hostname_f()
        url = "https://#{hostname}:8443/proxy/#{token}"
        socket = push_event(socket, "copy:text", %{text: url})
        {socket, state}

      {:event, socket, state = %{nets: nets, nid: nid, net: net}, "node:regen",
       %{"index" => index}} ->
        node = net.nodes[index]
        node = Wire.Store.regen(node)
        net = put_in(net, [:nodes, index], node)
        {^nid, net} = Wire.Store.save(:net, nid, net)
        state = Map.put(state, :nets, Map.put(nets, nid, net))
        state = Map.put(state, :net, net)
        {socket, state}

      {:event, socket, state = %{net: net}, "node:reset", %{"index" => index}} ->
        node = net.nodes[index]
        Bus.broadcast!("wire:reload", {net.name, node.suffix, node.pub})
        {socket, state}

      {:event, socket, state, _event, _params} ->
        {socket, state}

      {:info, socket, state, {"wire:error", _, error}} ->
        state = Map.put(state, :error, error)
        {socket, state}

      {:info, socket, state, {"wire:status", _, status}} ->
        state = Map.put(state, :status, status)
        {socket, state}

      {:info, socket, state, _event} ->
        {socket, state}

      {:close, _socket, _state, _reason} ->
        :ok
    end
  end
end

Terminal.view(path, Wire.View.handler(path, props), auth: auth)
