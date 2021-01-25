defmodule MailSniffexWeb.MailController do
  use MailSniffexWeb, :controller

  def download(conn, %{"message_key" => message_key, "file_key" => file_key, "type" => type}) do
    message_data = message_data(message_key)
    file_data = message_data.body[type] |> Enum.at(file_key |> String.to_integer())
    send_download(conn, {:binary, file_data.body}, filename: file_data.name)
  end

  def iframe(conn, %{"message_key" => message_key}) do
    message_data = message_data(message_key)
    data = case message_data.body["html"] do
      nil -> conn |> text("No HTML")
      data -> conn |> html(data)
    end
  end

  defp message_data(message_key) do
      message_key
      |> source_content()
      |> :mimemail.decode()
      |> MailSniffex.MailSourceParser.parse()
  end

  defp source_content(key) do
    case File.read("data/source/" <> key) do
      {:ok, content} -> content |> :erlang.binary_to_term()
      _ -> nil
    end
  end
end
