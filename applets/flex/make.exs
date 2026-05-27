alias Kernel.ParallelCompiler, as: KPC
Code.compiler_options(ignore_module_conflict: true)

build = Path.join(assets, "_build")
if optimize? or force?, do: File.rm_rf!(build)
File.mkdir_p!(build)

case applets
     |> Path.join("flex/**/*.ex")
     |> Path.wildcard()
     |> KPC.compile_to_path(build, return_diagnostics: true) do
  {:ok, _modules, _diagnostics} ->
    puts.("#{route}: make.exs success")

  {:error, _errors, _diagnostics} ->
    # warnings and errors are sent to stdout no matter what
    puts.("#{route}: make.exs error")
    # for d <- diagnostics[:runtime_warnings], do: puts.("#{route}: make.exs warn #{inspect(d)}")
    # for d <- diagnostics[:compile_warnings], do: puts.("#{route}: make.exs warn #{inspect(d)}")
    # if "dev" != System.get_env("TERMINAL_ENV") do
    #   for e <- errors, do: puts.("#{route}: make.exs error #{inspect(e)}")
    # end
end
