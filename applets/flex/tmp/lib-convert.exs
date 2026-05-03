use Terminal

# js sends pointer coordinates of different type depending on platform
toFloat = fn
  arg when is_float(arg) ->
    {:ok, arg}

  arg when is_integer(arg) ->
    {:ok, :erlang.float(arg)}

  arg when is_binary(arg) ->
    case Float.parse(arg) do
      {result, ""} -> {:ok, result}
      {_, _} -> {:error, "Invalid float format: #{arg} [#{Base.encode16(arg)}]"}
      _ -> {:error, "Invalid float format: #{arg} [#{Base.encode16(arg)}]"}
    end

  arg ->
    {:error, "Invalid float convert: #{inspect(arg)}"}
end

toInteger = fn
  arg when is_integer(arg) ->
    {:ok, arg}

  arg when is_binary(arg) ->
    case Integer.parse(arg) do
      {result, ""} -> {:ok, result}
      {_, _} -> {:error, "Invalid integer format: #{arg} [#{Base.encode16(arg)}]"}
      _ -> {:error, "Invalid integer format: #{arg} [#{Base.encode16(arg)}]"}
    end

  arg ->
    {:error, "Invalid integer convert: #{inspect(arg)}"}
end

:ok
