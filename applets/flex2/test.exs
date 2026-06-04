check = fn args, expected ->
  try do
    apply(Flex2.Setter, :check, args)
    if !is_nil(expected), do: throw({args, expected})
  catch
    e ->
      if !is_list(expected), do: throw({args, e})
      for {k, v} <- expected, do: if(e[k] != v, do: throw({args, expected, e}))
  end
end

check.([:a, nil, :binary], error: "binary required")
check.([:a, "", :binary], nil)

check.([:a, nil, :binary?], nil)
check.([:a, "", :binary?], nil)
check.([:a, 0, :binary?], error: "binary or nil required")

check.([:a, 0, {:in, [0]}], nil)
check.([:a, 1, {:in, [0]}], error: "not in [0]")

check.([:a, nil, {:list?, nil, :binary}], nil)
check.([:a, [], {:list?, 0, :binary}], nil)
check.([:a, [""], {:list?, 1, :binary}], nil)
check.([:a, [nil], {:list?, 1, :binary}], error: "binary required", property: "a[0]")

check.([:a, nil, {:integer, 0, 1}], error: "integer required")
check.([:a, 3, {:integer, 1, 2}], error: "<= 2 required")
check.([:a, 0, {:integer, 1, 2}], error: ">= 1 required")
check.([:a, 3, {:integer, 1, nil}], nil)
check.([:a, 0, {:integer, nil, 2}], nil)

:ok
