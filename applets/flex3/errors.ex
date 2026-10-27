defmodule Flex.Errors do
  use Terminal

  # confirmed phoenix error page shows proper http request phase exception stacktrace for both:
  # - invalid assigns in livescreen/render
  # - invalid assigns in livescreen/widget render (when flag size not null)
  # confirmed telemetry is included and started and does not need endpoint configuration
  # confirmed the error handler below catches render exceptions at the websocket phase
  # inclusion options:
  # - yeico_applet
  # - yeico_terminal/app
  # - yeico_terminal/sdk
  # - yeico_terminal/flex

  def attach() do
    api = Process.get(:__api__)

    hid = "live-view-crash-handler/#{Api.entry()}"
    :telemetry.detach(hid)

    :telemetry.attach_many(
      hid,
      [
        [:phoenix, :live_view, :mount, :exception],
        [:phoenix, :live_view, :render, :exception],
        [:phoenix, :live_view, :handle_params, :exception],
        [:phoenix, :live_view, :handle_event, :exception]
      ],
      fn event, measurements, metadata, config ->
        Process.put(:__api__, api)
        handle_exception(event, measurements, metadata, config)
      end,
      nil
    )
  end

  defp handle_exception(event, _measurements, metadata, _config) do
    # Extract structural details about the crash
    phase = Enum.join(event, ".")
    socket = metadata[:socket]
    view = if socket, do: socket.view, else: "Unknown LiveView"

    # Extract the actual Elixir exception and stacktrace
    %{kind: _kind, reason: reason, stacktrace: stacktrace} = metadata

    Log.error("""
    💥 LiveView Crash Detected over WebSocket!
    =========================================
    Phase: #{phase}
    LiveView: #{inspect(view)}
    Error Type: #{inspect(reason.__struct__)}
    Message: #{Exception.message(reason)}

    Stacktrace:
    #{Exception.format_stacktrace(stacktrace)}
    =========================================
    """)
  end
end
