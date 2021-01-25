defmodule MailSniffex.FormatUtils do
  def get_bytes(value) when is_integer(value), do: value

  def get_bytes(text) when is_binary(text), do: ~r{(\d+)([A-Z]+)} |> Regex.run(text, capture: :all_but_first) |> get_bytes_impl()

  def format_datetime(dt) do
    "#{dt.day}.#{zero_pad(dt.month)}.#{dt.year} #{zero_pad(dt.hour)}:#{zero_pad(dt.minute)}:#{
      zero_pad(dt.second)
    }"
  end

  defp get_bytes_impl([number, type]) when type === "GB", do: String.to_integer(number) * 1_000_000_000

  defp get_bytes_impl([number, type]) when type === "MB", do: String.to_integer(number) * 1_000_000

  defp get_bytes_impl(_), do: raise "Wrong format for LIMIT_SIZE. Use '1GB' or '1MB'."

  defp zero_pad(integer) do
    integer
    |> Integer.to_string()
    |> String.pad_leading(2, "0")
  end

end
