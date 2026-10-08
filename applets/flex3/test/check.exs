use Terminal

check = fn args, expected ->
  try do
    apply(Flex.Check, :check, args)
    if !is_nil(expected), do: raise(Api.inspect?({args, expected}))
  catch
    e ->
      # Api.warn(e: e, args: args, expected: expected)
      if !is_list(expected), do: throw({args, e})
      for {k, v} <- expected, do: if(e[k] != v, do: throw({args, expected, e}))
  end
end

check.([:name, nil, :any], error: "any required")
check.([:name, "", :any], nil)
check.([:name, 0, :any], nil)
check.([:name, nil, :any?], nil)
check.([:name, "", :any?], nil)
check.([:name, 0, :any?], nil)

check.([:name, 0, {:ge, 1}], error: ">= 1 required")
check.([:name, 1, {:ge, 1}], nil)
check.([:name, 2, {:ge, 1}], nil)

check.([:name, 0, {:ge, 1.0}], error: ">= 1.0 required")
check.([:name, 1, {:ge, 1.0}], nil)
check.([:name, 2, {:ge, 1.0}], nil)

check.([:name, 2, {:le, 1}], error: "<= 1 required")
check.([:name, 1, {:le, 1}], nil)
check.([:name, 0, {:le, 1}], nil)

check.([:name, 2, {:le, 1.0}], error: "<= 1.0 required")
check.([:name, 1, {:le, 1.0}], nil)
check.([:name, 0, {:le, 1.0}], nil)

check.([:name, nil, :integer], error: "integer required")
check.([:name, 0, :integer], nil)
check.([:name, nil, :integer?], nil)
check.([:name, 0, :integer?], nil)
check.([:name, "", :integer?], error: "integer? required")

check.([:name, nil, {:integer, nil, nil}], error: "integer required")
check.([:name, 0, {:integer, nil, nil}], nil)
check.([:name, 0, {:integer, 0, nil}], nil)
check.([:name, 0, {:integer, nil, 0}], nil)
check.([:name, 0, {:integer, 0, 0}], nil)
check.([:name, 0, {:integer, 1, nil}], error: ">= 1 required")
check.([:name, 2, {:integer, nil, 1}], error: "<= 1 required")

check.([:name, nil, :float], error: "float required")
check.([:name, 0.0, :float], nil)
check.([:name, nil, :float?], nil)
check.([:name, 0.0, :float?], nil)
check.([:name, "", :float?], error: "float? required")

check.([:name, nil, {:float, nil, nil}], error: "float required")
check.([:name, 0.0, {:float, nil, nil}], nil)
check.([:name, 0.0, {:float, 0.0, nil}], nil)
check.([:name, 0.0, {:float, nil, 0.0}], nil)
check.([:name, 0.0, {:float, 0.0, 0.0}], nil)
check.([:name, 0.0, {:float, 1.0, nil}], error: ">= 1.0 required")
check.([:name, 2.0, {:float, nil, 1.0}], error: "<= 1.0 required")

check.([:name, nil, :binary], error: "binary required")
check.([:name, "", :binary], nil)
check.([:name, nil, :binary?], nil)
check.([:name, "", :binary?], nil)
check.([:name, 0, :binary?], error: "binary? required")

check.([:name, nil, :boolean], error: "boolean required")
check.([:name, true, :boolean], nil)
check.([:name, nil, :boolean?], nil)
check.([:name, true, :boolean?], nil)
check.([:name, "", :boolean?], error: "boolean? required")

check.([:name, nil, :atom], error: "atom required")
check.([:name, :value, :atom], nil)
check.([:name, nil, :atom?], nil)
check.([:name, :value, :atom?], nil)
check.([:name, "", :atom?], error: "atom? required")

check.([:name, nil, :map], error: "map required")
check.([:name, %{}, :map], nil)
check.([:name, nil, :map?], nil)
check.([:name, %{}, :map?], nil)
check.([:name, "", :map?], error: "map? required")

check.([:name, 0, {:in, [0]}], nil)
check.([:name, 1, {:in, [0]}], error: "not in [0]")

check.([:name, nil, :list], error: "list required")
check.([:name, [], :list], nil)
check.([:name, nil, :list?], nil)
check.([:name, [], :list?], nil)
check.([:name, "", :list?], error: "list? required")

check.([:name, nil, {:list, 0}], error: "list0 required")
check.([:name, [], {:list, 0}], nil)
check.([:name, nil, {:list?, 0}], nil)
check.([:name, [], {:list?, 0}], nil)
check.([:name, "", {:list?, 0}], error: "list0? required")

check.([:name, nil, {:list, nil, :binary}], error: "list required")
check.([:name, [], {:list, nil, :binary}], nil)
check.([:name, [], {:list, 0, :binary}], nil)
check.([:name, [], {:list, 1, :binary}], error: "list1 required")
check.([:name, [""], {:list, 1, :binary}], nil)
check.([:name, [nil], {:list, 1, :binary}], error: "binary required", property: "name[0]")

check.([:name, "", {:list?, nil, :binary}], error: "list? required")
check.([:name, nil, {:list?, nil, :binary}], nil)
check.([:name, [], {:list?, nil, :binary}], nil)
check.([:name, [], {:list?, 0, :binary}], nil)
check.([:name, [], {:list?, 1, :binary}], error: "list1? required")
check.([:name, [""], {:list?, 1, :binary}], nil)
check.([:name, [nil], {:list?, 1, :binary}], error: "binary required", property: "name[0]")

check.([:name, nil, :tuple], error: "tuple required")
check.([:name, {}, :tuple], nil)
check.([:name, nil, :tuple?], nil)
check.([:name, {}, :tuple?], nil)
check.([:name, "", :tuple?], error: "tuple? required")

check.([:name, nil, {:tuple, 0}], error: "tuple0 required")
check.([:name, {}, {:tuple, 0}], nil)
check.([:name, nil, {:tuple?, 0}], nil)
check.([:name, {}, {:tuple?, 0}], nil)
check.([:name, "", {:tuple?, 0}], error: "tuple0? required")

check.([:name, nil, {:tuple, nil, :binary}], error: "tuple required")
check.([:name, {}, {:tuple, nil, :binary}], nil)
check.([:name, {}, {:tuple, 0, :binary}], nil)
check.([:name, {}, {:tuple, 1, :binary}], error: "tuple1 required")
check.([:name, {""}, {:tuple, 1, :binary}], nil)
check.([:name, {nil}, {:tuple, 1, :binary}], error: "binary required", property: "name[0]")

check.([:name, "", {:tuple?, nil, :binary}], error: "tuple? required")
check.([:name, nil, {:tuple?, nil, :binary}], nil)
check.([:name, {}, {:tuple?, nil, :binary}], nil)
check.([:name, {}, {:tuple?, 0, :binary}], nil)
check.([:name, {}, {:tuple?, 1, :binary}], error: "tuple1? required")
check.([:name, {""}, {:tuple?, 1, :binary}], nil)
check.([:name, {nil}, {:tuple?, 1, :binary}], error: "binary required", property: "name[0]")

check.([:name, nil, {:starts_with?, ""}], error: "binary required")
check.([:name, "", {:starts_with?, "0"}], error: "prefix 0 required")
check.([:name, "", {:starts_with?, ""}], nil)

check.([:name, nil, {:fun, 0}], error: "fun0 required")
check.([:name, fn -> nil end, {:fun, 0}], nil)
check.([:name, fn _ -> nil end, {:fun, 1}], nil)

check.([:name, "", {:fun?, 0}], error: "fun0? required")
check.([:name, nil, {:fun?, 0}], nil)
check.([:name, fn -> nil end, {:fun?, 0}], nil)

check.([:name, nil, fn _, _ -> nil end], nil)

:ok
