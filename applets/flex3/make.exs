Code.compiler_options(ignore_module_conflict: true)
Code.purge_compiler_modules()

build = Path.join(assets, "_build")

build
|> Path.join("*.beam")
|> Path.wildcard()
|> Enum.map(&Path.basename(&1, ".beam"))
|> Enum.map(&String.to_atom(&1))
|> Enum.each(fn m ->
  # puts.("#{route}: purge #{m}")
  # The BEAM runtime can hold exactly two versions of a module in memory at any given time
  :code.purge(m)
  :code.purge(m)
end)

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
