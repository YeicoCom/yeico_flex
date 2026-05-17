use Flex

idb = Db.open("user-files")
Api.putcast!("flex:user-files:items", [])
Api.putcast!("flex:user-files:logs", %{})
udir = Terminal.dpath("@home/flex/upload")
sdir = Api.path("static/upload")

if {:ok, udir} != File.read_link(sdir) do
  {:ok, _} = File.rm_rf(sdir)
  :ok = File.ln_s(udir, sdir)
end

Flex.eval_file("iutils.exs", [])
Flex.eval_file("loop.exs", [])
Flex.eval_file("index.exs", [])
Flex.eval_file("publish.exs", [])

Flex.run_view("index.exs", Flex.UserFiles.Index, idb: idb, udir: udir)
Flex.run_loop("userfiles:loop", 2_000, Flex.UserFiles.Loop, idb: idb, udir: udir)
Flex.run_loop("userfiles:publish", 0, Flex.UserFiles.Publish, [])

Api.putcast!("flex:point:file:yeicologo", "logo.svg")
Mdb.register!("flex:points:file", "yeicologo:Yeico Logo")

:ok
