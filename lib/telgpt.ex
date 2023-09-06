defmodule Telgpt do
  use ThousandIsland.Handler

  @impl ThousandIsland.Handler
  def handle_connection(socket, state) do
    socket
    |> ThousandIsland.Socket.send("Welcome to TelGPT!\n\n> ")
    {:continue, state}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    socket |> ThousandIsland.Socket.send("\n")
    Task.async(fn ->
      chat_completion(data, socket)
    end)
    |> Task.await(180 * 1000)
    socket |> ThousandIsland.Socket.send("\n\n> ")

    {:continue, state}
  end

  # When `stream_to` is set in the http_options,
  # the GenServer will receive this message when
  # the stream is closed.
  @impl GenServer
  def handle_info({:EXIT, _pid, :normal}, state) do
    {:noreply, state}
  end

  defp chat_completion(data, socket) do
    OpenAI.chat_completion(
      [
        model: "gpt-4",
        messages: [
          %{role: "user", content: data}
        ],
        stream: true
      ],
      %OpenAI.Config{
        api_key: System.get_env("OPENAI_API_KEY"),
        http_options: [recv_timeout: :infinity, stream_to: self(), async: :once]
      }
    )
    |> Stream.flat_map(fn res -> res["choices"] end)
    |> Stream.each(fn choice ->
      socket
      |> ThousandIsland.Socket.send(choice["delta"]["content"])
    end)
    |> Stream.run()
  end
end
