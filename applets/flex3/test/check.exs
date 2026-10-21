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

check.([:path, nil, :any], error: "any required")
check.([:path, "", :any], nil)
check.([:path, 0, :any], nil)
check.([:path, nil, :any?], nil)
check.([:path, "", :any?], nil)
check.([:path, 0, :any?], nil)

check.([:path, 0, {:ge, 1}], error: ">= 1 required")
check.([:path, 1, {:ge, 1}], nil)
check.([:path, 2, {:ge, 1}], nil)

check.([:path, 0, {:ge, 1.0}], error: ">= 1.0 required")
check.([:path, 1, {:ge, 1.0}], nil)
check.([:path, 2, {:ge, 1.0}], nil)

check.([:path, 2, {:le, 1}], error: "<= 1 required")
check.([:path, 1, {:le, 1}], nil)
check.([:path, 0, {:le, 1}], nil)

check.([:path, 2, {:le, 1.0}], error: "<= 1.0 required")
check.([:path, 1, {:le, 1.0}], nil)
check.([:path, 0, {:le, 1.0}], nil)

check.([:path, nil, :integer], error: "integer required")
check.([:path, 0, :integer], nil)
check.([:path, nil, :integer?], nil)
check.([:path, 0, :integer?], nil)
check.([:path, "", :integer?], error: "integer? required")

check.([:path, nil, {:integer, nil, nil}], error: "integer required")
check.([:path, 0, {:integer, nil, nil}], nil)
check.([:path, 0, {:integer, 0, nil}], nil)
check.([:path, 0, {:integer, nil, 0}], nil)
check.([:path, 0, {:integer, 0, 0}], nil)
check.([:path, 0, {:integer, 1, nil}], error: ">= 1 required")
check.([:path, 2, {:integer, nil, 1}], error: "<= 1 required")

check.([:path, nil, :float], error: "float required")
check.([:path, 0.0, :float], nil)
check.([:path, nil, :float?], nil)
check.([:path, 0.0, :float?], nil)
check.([:path, "", :float?], error: "float? required")

check.([:path, nil, {:float, nil, nil}], error: "float required")
check.([:path, 0.0, {:float, nil, nil}], nil)
check.([:path, 0.0, {:float, 0.0, nil}], nil)
check.([:path, 0.0, {:float, nil, 0.0}], nil)
check.([:path, 0.0, {:float, 0.0, 0.0}], nil)
check.([:path, 0.0, {:float, 1.0, nil}], error: ">= 1.0 required")
check.([:path, 2.0, {:float, nil, 1.0}], error: "<= 1.0 required")

check.([:path, nil, :number], error: "number required")
check.([:path, 0, :number], nil)
check.([:path, 0.0, :number], nil)
check.([:path, nil, :number?], nil)
check.([:path, 0, :number?], nil)
check.([:path, 0.0, :number?], nil)
check.([:path, "", :number?], error: "number? required")

check.([:path, nil, {:number, nil, nil}], error: "number required")
check.([:path, 0.0, {:number, nil, nil}], nil)
check.([:path, 0.0, {:number, 0.0, nil}], nil)
check.([:path, 0.0, {:number, nil, 0.0}], nil)
check.([:path, 0.0, {:number, 0.0, 0.0}], nil)
check.([:path, 0.0, {:number, 1.0, nil}], error: ">= 1.0 required")
check.([:path, 2.0, {:number, nil, 1.0}], error: "<= 1.0 required")

check.([:path, nil, :binary], error: "binary required")
check.([:path, "", :binary], nil)
check.([:path, nil, :binary?], nil)
check.([:path, "", :binary?], nil)
check.([:path, 0, :binary?], error: "binary? required")

check.([:path, nil, :boolean], error: "boolean required")
check.([:path, true, :boolean], nil)
check.([:path, nil, :boolean?], nil)
check.([:path, true, :boolean?], nil)
check.([:path, "", :boolean?], error: "boolean? required")

check.([:path, nil, :atom], error: "atom required")
check.([:path, :value, :atom], nil)
check.([:path, nil, :atom?], nil)
check.([:path, :value, :atom?], nil)
check.([:path, "", :atom?], error: "atom? required")

check.([:path, nil, :map], error: "map required")
check.([:path, %{}, :map], nil)
check.([:path, nil, :map?], nil)
check.([:path, %{}, :map?], nil)
check.([:path, "", :map?], error: "map? required")

check.([:path, 0, {:in, [0]}], nil)
check.([:path, 1, {:in, [0]}], error: "not in [0]")

check.([:path, nil, :list], error: "list required")
check.([:path, [], :list], nil)
check.([:path, nil, :list?], nil)
check.([:path, [], :list?], nil)
check.([:path, "", :list?], error: "list? required")

check.([:path, nil, {:list, 0}], error: "list0 required")
check.([:path, [], {:list, 0}], nil)
check.([:path, nil, {:list?, 0}], nil)
check.([:path, [], {:list?, 0}], nil)
check.([:path, "", {:list?, 0}], error: "list0? required")

check.([:path, nil, {:list, nil, :binary}], error: "list required")
check.([:path, [], {:list, nil, :binary}], nil)
check.([:path, [], {:list, 0, :binary}], nil)
check.([:path, [], {:list, 1, :binary}], error: "list1 required")
check.([:path, [""], {:list, 1, :binary}], nil)
check.([:path, [nil], {:list, 1, :binary}], error: "binary required", path: "path[0]")

check.([:path, "", {:list?, nil, :binary}], error: "list? required")
check.([:path, nil, {:list?, nil, :binary}], nil)
check.([:path, [], {:list?, nil, :binary}], nil)
check.([:path, [], {:list?, 0, :binary}], nil)
check.([:path, [], {:list?, 1, :binary}], error: "list1? required")
check.([:path, [""], {:list?, 1, :binary}], nil)
check.([:path, [nil], {:list?, 1, :binary}], error: "binary required", path: "path[0]")

check.([:path, nil, :tuple], error: "tuple required")
check.([:path, {}, :tuple], nil)
check.([:path, nil, :tuple?], nil)
check.([:path, {}, :tuple?], nil)
check.([:path, "", :tuple?], error: "tuple? required")

check.([:path, nil, {:tuple, 0}], error: "tuple0 required")
check.([:path, {}, {:tuple, 0}], nil)
check.([:path, nil, {:tuple?, 0}], nil)
check.([:path, {}, {:tuple?, 0}], nil)
check.([:path, "", {:tuple?, 0}], error: "tuple0? required")

check.([:path, nil, {:tuple, nil, :binary}], error: "tuple required")
check.([:path, {}, {:tuple, nil, :binary}], nil)
check.([:path, {}, {:tuple, 0, :binary}], nil)
check.([:path, {}, {:tuple, 1, :binary}], error: "tuple1 required")
check.([:path, {""}, {:tuple, 1, :binary}], nil)
check.([:path, {nil}, {:tuple, 1, :binary}], error: "binary required", path: "path[0]")

check.([:path, "", {:tuple?, nil, :binary}], error: "tuple? required")
check.([:path, nil, {:tuple?, nil, :binary}], nil)
check.([:path, {}, {:tuple?, nil, :binary}], nil)
check.([:path, {}, {:tuple?, 0, :binary}], nil)
check.([:path, {}, {:tuple?, 1, :binary}], error: "tuple1? required")
check.([:path, {""}, {:tuple?, 1, :binary}], nil)
check.([:path, {nil}, {:tuple?, 1, :binary}], error: "binary required", path: "path[0]")

check.([:path, nil, {:starts_with?, ""}], error: "binary required")
check.([:path, "", {:starts_with?, "0"}], error: "prefix 0 required")
check.([:path, "", {:starts_with?, ""}], nil)

check.([:path, nil, {:fun, 0}], error: "fun0 required")
check.([:path, fn -> nil end, {:fun, 0}], nil)
check.([:path, fn _ -> nil end, {:fun, 1}], nil)

check.([:path, "", {:fun?, 0}], error: "fun0? required")
check.([:path, nil, {:fun?, 0}], nil)
check.([:path, fn -> nil end, {:fun?, 0}], nil)

check.([:path, nil, fn _, _ -> nil end], nil)

check.([:path, nil, :sink], error: "tuple2 required")
check.([:path, {:other, nil}, :sink], error: "invalid sink")
check.([:path, {:shared, "key"}, :sink], error: "atom required")
check.([:path, {:point, "point"}, :sink], nil)
check.([:path, {:shared, :key}, :sink], nil)

check.([:path, nil, :sink?], nil)
check.([:path, {:other, nil}, :sink?], error: "invalid sink")
check.([:path, {:shared, "key"}, :sink?], error: "atom required")
check.([:path, {:point, "point"}, :sink?], nil)
check.([:path, {:shared, :key}, :sink?], nil)

check.([:path, nil, :source], error: "tuple2 required")
check.([:path, {:other, nil}, :source], error: "invalid source")
check.([:path, {:shared, "key"}, :source], error: "atom required")
check.([:path, {:const, 1}, :source], nil)
check.([:path, {:timer, 1}, :source], nil)
check.([:path, {:point, "point"}, :source], nil)
check.([:path, {:shared, :key}, :source], nil)

check.([:path, nil, :source?], nil)
check.([:path, {:other, nil}, :source?], error: "invalid source")
check.([:path, {:shared, "key"}, :source?], error: "atom required")
check.([:path, {:const, 1}, :source?], nil)
check.([:path, {:timer, 1}, :source?], nil)
check.([:path, {:point, "point"}, :source?], nil)
check.([:path, {:shared, :key}, :source?], nil)

check.([:path, nil, :input], error: "tuple2 required")
check.([:path, {:other, nil}, :input], error: "tuple2 required")
check.([:path, {:other, {:other, nil}}, :input], error: "invalid source")
check.([:path, {:other, {:shared, "key"}}, :input], error: "atom required")
check.([:path, {:name, {:const, 1}}, :input], nil)
check.([:path, {:name, {:timer, 1}}, :input], nil)
check.([:path, {:name, {:point, "point"}}, :input], nil)
check.([:path, {:name, {:shared, :key}}, :input], nil)

:ok
