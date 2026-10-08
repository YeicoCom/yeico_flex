use Terminal

{:module, :erl_eval} = Function.info(fn -> nil end, :module)
{:module, Applet.Api} = Function.info(Api.wrap(fn -> nil end), :module)
{:module, Applet.Api} = Function.info(Api.wrapper().(fn -> nil end), :module)

:ok
