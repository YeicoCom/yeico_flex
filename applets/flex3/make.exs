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

# assets received from sdk, points to the applets (flex3.exs) folder (/applets/flex3)
prefix = ~c"#{assets}"

# only way to unload a using macro that compiled but failed to
# execute during compilation of a diffent module that used it
# macros errors may not trigger until they are run
:code.all_loaded()
|> Enum.filter(fn {_m, p} -> is_list(p) end)
|> Enum.filter(fn {_m, p} -> :lists.prefix(prefix, p) end)
|> Enum.each(fn {m, _p} ->
  # IO.inspect(m)
  :code.delete(m)
  :code.purge(m)
end)

build = Path.join(assets, "_build")
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
