# for nodes pending applet update
Code.compiler_options(ignore_module_conflict: true)

build = Path.join(assets, "_build")
File.rm_rf!(build)
File.mkdir_p!(build)

case applets
     |> Path.join("flex/**/*.ex")
     |> Path.wildcard()
     |> (fn files ->
           # run async to avoid flooding of flush exit logs
           alias Kernel.ParallelCompiler, as: KPC
           opts = [return_diagnostics: true]
           task = Task.async(fn -> KPC.compile_to_path(files, build, opts) end)
           Task.await(task, :infinity)
         end).() do
  {:ok, _modules, _diagnostics} ->
    puts.("#{route}: make.exs success")

  {:error, _errors, _diagnostics} ->
    puts.("#{route}: make.exs error")
    # warnings and errors are sent to stdout anyway
    # for d <- diagnostics[:runtime_warnings], do: puts.("#{route}: make.exs warn #{inspect(d)}")
    # for d <- diagnostics[:compile_warnings], do: puts.("#{route}: make.exs warn #{inspect(d)}")
    # if "dev" != System.get_env("TERMINAL_ENV") do
    #   for e <- errors, do: puts.("#{route}: make.exs error #{inspect(e)}")
    # end
end
