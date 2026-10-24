use Terminal.Live

view = fn assigns ->
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
          <div class="px-4 grid grid-cols-[3em_8em_4em_1fr_1fr_1fr_7em]">
            <div/>
            <div>Name</div>
            <div>Suffix</div>
            <div>Exports</div>
            <div>Imports</div>
            <div>Status</div>
            <div>Actions</div>
          </div>
          <div class="grow flex flex-col gap-1 overflow-y-auto">
            <div :for={{index, n} <- @nodes} class="px-4 grid grid-cols-[3em_8em_4em_1fr_1fr_1fr_7em] hover:bg-base-300 cursor-pointer"
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
                  <div class="hero-arrow-path" title="Regenerate Keys" phx-click="node:regen" phx-value-index={index}/>
                  <div class="hero-arrow-path" title="Reset Peer" phx-click="node:reset" phx-value-index={index}/>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <.fui fun={&Wire.UI.modal/1} :if={@modal[:type] == :network}
    title={@modal[:title]} class="min-w-[360px] flex flex-col gap-4">
      <form id="modal_form" phx-submit="network:save" class="flex flex-col gap-4"
        phx-hook="Form" phx-update="ignore" autocomplete="off">
        <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
          <input type="hidden" name="nid" value={@modal[:nid]}>
          <div>Name</div>
          <.fui fun={&Wire.UI.input/1} name="name" value={@modal[:net][:name]} type="text" required id="modal_autofocus" phx-hook="Focus"/>
          <div>Prefix</div>
          <.fui fun={&Wire.UI.input/1} name="prefix" value={@modal[:net][:prefix]} type="text" required/>
          <div>Port</div>
          <.fui fun={&Wire.UI.input/1} name="port" value={@modal[:net][:port]} type="number" step="1" min="1" max="65535" required/>
          <div>Status</div>
          <.fui fun={&Wire.UI.select/1} name="status" value={@modal[:net][:status]} values={["Enabled", "Disabled"]} required/>
        </div>
        <div class="grid grid-cols-2 gap-2 items-center">
          <.fui fun={&Wire.UI.link/1} type="danger" phx-click="network:delete" phx-value-nid={@modal[:nid]}>Delete</.fui>
          <.fui fun={&Wire.UI.button/1} type="submit">Accept</.fui>
        </div>
      </form>
  </.fui>
  <.fui fun={&Wire.UI.modal/1} :if={@modal[:type] == :node}
    title={@modal[:title]} class="min-w-[360px] flex flex-col gap-4">
      <form id="modal_form" phx-submit="node:save" class="flex flex-col gap-4"
        phx-hook="Form" phx-update="ignore" autocomplete="off">
        <div class="grid grid-cols-2 gap-2 items-center min-w-[12em]">
          <input type="hidden" name="index" value={@modal[:index]}>
          <div>Name</div>
          <.fui fun={&Wire.UI.input/1} name="name" value={@modal[:node][:name]} type="text" required id="modal_autofocus" phx-hook="Focus"/>
          <div>Suffix</div>
          <.fui fun={&Wire.UI.input/1} name="suffix" value={@modal[:node][:suffix]} type="text" required/>
          <div>Exports</div>
          <.fui fun={&Wire.UI.input/1} name="exports" value={@modal[:node][:exports]} type="text"/>
          <div>Imports</div>
          <.fui fun={&Wire.UI.input/1} name="imports" value={@modal[:node][:imports]} type="text"/>
          <div>Status</div>
          <.fui fun={&Wire.UI.select/1} name="status" value={@modal[:node][:status]} values={["Enabled", "Disabled"]} required/>
        </div>
        <div class="grid grid-cols-2 gap-2 items-center">
          <div>
          <.fui fun={&Wire.UI.link/1} type="danger" phx-click="node:delete" phx-value-index={@modal[:index]}>Delete</.fui>
          </div>
          <.fui fun={&Wire.UI.button/1} type="submit">Accept</.fui>
        </div>
      </form>
  </.fui>
  """
end

handler = fn
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
    state = Map.put(state, :nets, Wire.Db.list())
    state = Map.put(state, :modal, nil)
    state = Map.put(state, :net, nil)
    state = Map.put(state, :nid, nil)
    {socket, state}

  {:params, socket, state, params, uri} ->
    Log.trace(view: path, params: params, uri: uri)
    {socket, state}

  {:render, _assigns, state = %{nets: nets, net: net}} ->
    nets = Enum.sort_by(nets, fn {_, %{name: name}} -> name end)
    state = Map.put(state, :nets, nets)
    nodes = net[:nodes] || %{}
    sorter = fn {_, %{suffix: su, name: na}} -> {String.to_integer(su), na} end
    nodes = Enum.sort_by(nodes, sorter)
    state = Map.put(state, :nodes, nodes)
    view.(state)

  {:event, socket, state, event = "modal:close", params} ->
    Log.trace(view: path, event: event, params: params)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "network:add", params} ->
    Log.trace(view: path, event: event, params: params)
    state = Map.put(state, :modal, %{type: :network, title: "Add Network"})
    {socket, state}

  {:event, socket, state = %{nets: nets}, event = "network:edit", params = %{"nid" => nid}} ->
    Log.trace(view: path, event: event, params: params)
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

  {:event, socket, state = %{net: net, nets: nets}, event = "network:save",
   params = %{
     "nid" => nid,
     "name" => name,
     "prefix" => prefix,
     "port" => port,
     "status" => status
   }} ->
    Log.trace(view: path, event: event, params: params)
    name = String.trim(name)
    prefix = String.trim(prefix)
    port = String.trim(port)
    status = String.trim(status)
    {nid, net} = if(nid == "", do: Wire.Db.def(), else: {nid, net})
    net = Map.merge(net, %{name: name, prefix: prefix, port: port, status: status})
    {nid, net} = Wire.Db.save(:net, nid, net)
    state = Map.put(state, :nets, Map.put(nets, nid, net))
    state = Map.put(state, :net, net)
    state = Map.put(state, :nid, nid)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{nets: nets}, event = "network:select", params = %{"nid" => nid}} ->
    Log.trace(view: path, event: event, params: params)
    state = Map.put(state, :net, nets[nid])
    state = Map.put(state, :nid, nid)
    {socket, state}

  {:event, socket, state = %{nets: nets}, event = "network:delete", params = %{"nid" => nid}} ->
    Log.trace(view: path, event: event, params: params)
    :ok = Wire.Db.delete(:net, nid)
    state = Map.put(state, :nets, Map.delete(nets, nid))
    state = Map.put(state, :net, nil)
    state = Map.put(state, :nid, nil)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state, event = "node:add", params} ->
    Log.trace(view: path, event: event, params: params)
    state = Map.put(state, :modal, %{type: :node, title: "Add Node"})
    {socket, state}

  {:event, socket, state = %{net: net}, event = "node:edit", params = %{"index" => index}} ->
    Log.trace(view: path, event: event, params: params)
    node = net.nodes[index]
    state = Map.put(state, :modal, %{type: :node, title: "Edit Node", index: index, node: node})
    {socket, state}

  {:event, socket, state = %{nid: nid, net: net, nets: nets}, event = "node:save",
   params = %{
     "index" => index,
     "name" => name,
     "suffix" => suffix,
     "imports" => imports,
     "exports" => exports,
     "status" => status
   }} ->
    Log.trace(view: path, event: event, params: params)
    name = String.trim(name)
    suffix = String.trim(suffix)
    imports = String.trim(imports)
    exports = String.trim(exports)
    status = String.trim(status)
    node = %{name: name, suffix: suffix, imports: imports, exports: exports, status: status}
    net = put_in(net, [:nodes, index], node)
    {^nid, net} = Wire.Db.save(:net, nid, net)
    state = Map.put(state, :nets, Map.put(nets, nid, net))
    state = Map.put(state, :net, net)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{nid: nid, net: net, nets: nets}, event = "node:delete",
   params = %{"index" => index}} ->
    Log.trace(view: path, event: event, params: params)
    {_, net} = pop_in(net, [:nodes, index])
    {^nid, net} = Wire.Db.save(:net, nid, net)
    state = Map.put(state, :nets, Map.put(nets, nid, net))
    state = Map.put(state, :net, net)
    state = Map.put(state, :modal, nil)
    {socket, state}

  {:event, socket, state = %{net: net}, event = "net:hosts", params} ->
    Log.trace(view: path, event: event, params: params)
    socket = push_event(socket, "copy:text", %{text: Wire.Template.hosts(net)})
    {socket, state}

  {:event, socket, state = %{net: net}, event = "node:conf", params = %{"index" => index}} ->
    Log.trace(view: path, event: event, params: params)
    socket = push_event(socket, "copy:text", %{text: Wire.Template.node(net, index)})
    {socket, state}

  {:event, socket, state = %{net: net}, event = "node:yaml", params = %{"index" => index}} ->
    Log.trace(view: path, event: event, params: params)
    socket = push_event(socket, "copy:text", %{text: Wire.Template.yaml(net, index)})
    {socket, state}

  {:event, socket, state = %{nets: nets, nid: nid, net: net}, event = "node:regen",
   params = %{"index" => index}} ->
    Log.trace(view: path, event: event, params: params)
    node = net.nodes[index]
    node = Wire.Db.regen(node)
    net = put_in(net, [:nodes, index], node)
    {^nid, net} = Wire.Db.save(:net, nid, net)
    state = Map.put(state, :nets, Map.put(nets, nid, net))
    state = Map.put(state, :net, net)
    {socket, state}

  {:event, socket, state = %{net: net}, event = "node:reset", params = %{"index" => index}} ->
    Log.trace(view: path, event: event, params: params)
    node = net.nodes[index]
    Bus.broadcast!("wire:reload", {net.name, node.suffix, node.pub})
    {socket, state}

  {:event, socket, state, event, params} ->
    Log.trace(view: path, event: event, params: params)
    {socket, state}

  {:info, socket, state, event = {"wire:error", _, error}} ->
    Log.trace(view: path, info: event)
    state = Map.put(state, :error, error)
    {socket, state}

  {:info, socket, state, event = {"wire:status", _, status}} ->
    Log.trace(view: path, info: event)
    state = Map.put(state, :status, status)
    {socket, state}

  {:info, socket, state, event} ->
    Log.trace(view: path, info: event)
    {socket, state}

  {:close, _socket, _state, reason} ->
    Log.trace(view: path, close: reason)
    :ok
end

Terminal.view(path, handler, auth: auth)
