use Terminal

# logging requires __api__ for entry and route for both script and module functions
# script functions require on definition wrapping for accurante stacktraces no matter the execution point
# unwrapped script functions generate accurate stacktraces only when executed during the evaluation of their script file
#
# Api.wrap logs unhandled exceptions
# Api.wrapper() does not

{:module, :erl_eval} = Function.info(fn -> nil end, :module)
{:module, Applet.Api} = Function.info(Api.wrap(fn -> nil end), :module)
{:module, Applet.Api} = Function.info(Api.wrapper().(fn -> nil end), :module)

:ok
