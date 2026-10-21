defmodule Flex.Parse do
  def float!(string) do
    case float(string) do
      {:error, error} -> throw(error)
      {:ok, value} -> value
    end
  end

  def float(string) do
    # Float.parse(".3") returns :error
    # Float.parse("0.") returns{0.0, "."}
    string = String.trim(string)

    string =
      cond do
        string == "." -> string
        String.starts_with?(string, ".") -> "0" <> string
        String.ends_with?(string, ".") -> string <> "0"
        true -> string
      end

    case Float.parse(string) do
      {value, ""} ->
        {:ok, value}

      {_, _} ->
        {:error, string}

      :error ->
        case Integer.parse(string) do
          {value, ""} ->
            {:ok, 1.0 * value}

          _ ->
            {:error, string}
        end
    end
  end
end
