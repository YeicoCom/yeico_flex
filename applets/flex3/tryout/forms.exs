use Terminal.Live

render = fn assigns ->
  ~H"""
  <form phx-submit="form:submit" class="p-4 flex flex-col gap-1 bg-neutral-200 text-neutral-500">
    <input type="text" class="form-input" value="Form Input">
    <input type="text" class="form-input" value="Form Input" readonly>
    <input type="text" class="form-input" value="Form Input" disabled>
    <input type="number" class="form-input" value="1.23">
    <input type="number" class="form-input" value="1.23" readonly>
    <input type="number" class="form-input" value="1.23" disabled>
    <select class="form-select">
      <option value="1">One</option>
      <option value="2">Two</option>
    </select>
    <select class="form-select" disabled>
      <option value="1">One</option>
      <option value="2">Two</option>
    </select>
    <select size="4" class="form-select">
      <option value="1">One</option>
      <option value="2">Two</option>
    </select>
    <select size="4" class="form-select" disabled>
      <option value="1">One</option>
      <option value="2">Two</option>
    </select>
    <div class="flex items-center gap-2">
      <div class="flex items-center gap-1">
        <input type="radio" name="r" id="r1" class="form-radio">
        <label for="r1">Radio1</label>
      </div>
      <div class="flex items-center gap-1">
        <input type="radio" name="r" id="r2" class="form-radio" checked>
        <label for="r2">Radio2</label>
      </div>
      <div class="flex items-center gap-1">
        <input type="radio" name="r" id="r3" class="form-radio" disabled>
        <label for="r3">Radio3</label>
      </div>
    </div>
    <button class="form-button">Click me</button>
    <button class="form-button" disabled>Click me</button>
    <textarea lines="3" class="form-textarea">Hello&#10;World</textarea>
    <textarea lines="3" class="form-textarea" readonly>Hello&#10;World</textarea>
    <textarea lines="3" class="form-textarea" disabled>Hello&#10;World</textarea>
  </form>
  """
end

Api.evalf("flex3/tryout/form1.exs", render: render, path: "/form1")
Api.evalf("flex3/tryout/form2.exs", render: render)

:ok
