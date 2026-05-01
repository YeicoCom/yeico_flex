use Terminal

# required to parse forms
# nil to disable check
getType = fn
  :uint16 -> %{name: :uint16, parent: :integer, min: 0x0000, max: 0xFFFF}
  :sint16 -> %{name: :sint16, parent: :integer, min: -32_768, max: 32_767}
  :float -> %{name: :float, parent: :integer, min: nil, max: nil}
  :bit -> %{name: :bit, parent: :integer, min: 0, max: 1}
  "uint16:" <> _ -> %{name: :uint16, parent: :integer, min: 0x0000, max: 0xFFFF}
  "sint16:" <> _ -> %{name: :sint16, parent: :integer, min: -32_768, max: 32_767}
  "float:" <> _ -> %{name: :float, parent: :float, min: nil, max: nil}
  "bit:" <> _ -> %{name: :bit, parent: :integer, min: nil, max: nil}
end

:ok
