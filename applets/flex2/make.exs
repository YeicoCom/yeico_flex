Code.compiler_options(ignore_module_conflict: true)

build = Path.join(assets, "_build")
if optimize? or full?, do: File.rm_rf!(build)
File.mkdir_p!(build)

case assets
     |> Path.join("**/*.ex")
     |> Path.wildcard()
     |> Kernel.ParallelCompiler.compile_to_path(build, return_diagnostics: true) do
  {:ok, _modules, _diagnostics} ->
    puts.("#{route}: make.exs success")

  {:error, _errors, _diagnostics} ->
    # warnings and errors are sent to stdout no matter what
    puts.("#{route}: make.exs error")
end
