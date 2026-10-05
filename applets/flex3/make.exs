# Issue: Need to save file twice for the compiler to notice errors within using macros.
# see https://elixir.hexdocs.pm/macro-anti-patterns.html
# Macros are tricky to compile, they need to be loaded in memory during compilation
# when the calling modules is compiled and the macro needed, beam files are checked
# and loaded if present, or compiled first if not, so it is critical to unload and
# delete them to ensure the latest source code is compiled and loaded.
# Therefore all modules are unloaded and the whole _build folder is deleted.
# Compiling using elixirc requires loadable terminal app beams.

# drop module already defined warnings
Code.compiler_options(ignore_module_conflict: true)

build = Path.join(assets, "_build")

build
|> Path.join("*.beam")
|> Path.wildcard()
|> Enum.map(&Path.basename(&1, ".beam"))
|> Enum.map(&String.to_atom(&1))
|> Enum.each(fn m ->
  # puts.("#{route}: purge #{m}")
  # puts.("#{route}: loaded? #{m} #{Code.loaded?(m)}")
  :code.delete(m)
  :code.purge(m)
  # puts.("#{route}: loaded? #{m} #{Code.loaded?(m)}")
end)

File.rm_rf!(build)
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
