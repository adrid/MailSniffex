defmodule MailSniffex.Server do
  require Logger
  @behaviour :gen_smtp_server_session
  @data_path Application.compile_env(:mail_sniffex, :data_path)
  @allowed_headers Application.compile_env(:mail_sniffex, :allowed_headers)

  def init(hostname, session_count, _address, _options) do
    if session_count > 40 do
      Logger.warn("Server connection limit exceeded")
      {:stop, :normal, ["421", hostname, " is too busy to accept mail right now"]}
    else
      banner = [hostname, " ESMTP"]
      state = %{}
      {:ok, banner, state}
    end
  end

  # credo:disable-for-next-line
  def handle_DATA(_from, _to, data, state) do
    Logger.info("Received DATA:")
    mail = parse_mail(data)

    # handle source - data
    # handle headers
    # handle saving files
    key = get_next_id()

    data_path =
      @data_path
      |> Path.join("source")

    File.mkdir_p(data_path)

    data_path
    |> Path.join(key)
    |> File.write(data |> :erlang.term_to_binary())

    message = %{
      headers: mail.headers |> Map.take(@allowed_headers),
      attachments:
        get_in(mail, [Access.key("attachments", [])])
        |> Enum.map(fn file -> %{name: file.name, id: file.id} end),
      inline_files:
        get_in(mail, [Access.key("inline_files", [])])
        |> Enum.map(fn file -> %{name: file.name, id: file.id} end),
      datetime: DateTime.utc_now(),
      unread: true,
      version: 1
    }

    MailSniffex.DB.get_db()
    |> CubDB.put(key, message)

    broadcast_message({key, message}, :message_created)
    MailSniffex.SizeWatcher.request_current_size()

    state
    |> Map.put(:body, data)

    {:ok, unique_id(), state}
  end

  # credo:disable-for-next-line
  def handle_EHLO(hostname, extensions, state) do
    Logger.info("EHLO #{hostname}")
    {:ok, extensions, state}
  end

  # credo:disable-for-next-line
  def handle_HELO(hostname, state) do
    Logger.info("HELO #{hostname}")
    {:ok, state}
  end

  # credo:disable-for-next-line
  def handle_MAIL(from, state) do
    Logger.info("MAIL from #{from}")
    {:ok, Map.put(state, :from, from)}
  end

  # credo:disable-for-next-line
  def handle_MAIL_extension(extension, state) do
    Logger.info(extension)
    {:ok, state}
  end

  # credo:disable-for-next-line
  def handle_RCPT(to, state) do
    Logger.info("RCPT to #{to}")
    {:ok, Map.put(state, :to, to)}
  end

  # credo:disable-for-next-line
  def handle_RCPT_extension(extension, state) do
    Logger.info(extension)
    {:ok, state}
  end

  # credo:disable-for-next-line
  def handle_RSET(state) do
    state =
      state
      |> Map.delete(:rcpt)
      |> Map.delete(:from)
      |> Map.delete(:to)
      |> Map.delete(:body)
    {:ok, state}
  end

  # credo:disable-for-next-line
  def handle_STARTTLS(state) do
    {:ok, state}
  end

  # credo:disable-for-next-line
  def handle_VRFY(user, state) do
    Logger.info(user)
    {:ok, '#{user}@#{:smtp_util.guess_FQDN()}', state}
  end

  def handle_other(command, _args, state) do
    Logger.info(command)
    {:noreply, state}
  end

  def code_change(_old, state, _extra) do
    {:ok, state}
  end

  def terminate(reason, state) do
    Logger.info("Terminating Session")
    IO.inspect(reason)
    {:ok, reason, state}
  end

  defp parse_mail(data) do
    :mimemail.decode(data)
    |> MailSniffex.MailSourceParser.parse()
  end

  defp broadcast_message(message, event) do
    Phoenix.PubSub.broadcast(MailSniffex.PubSub, "messages", {event, message})
  end

  defp get_next_id(iterator \\ 0) do
    {:ok, time} = DateTime.now("Etc/UTC")

    str_time =
      time
      |> DateTime.to_unix()
      |> Integer.to_string()

    iterator_string = iterator
    |> Integer.to_string()
    |> String.pad_leading(6, "0")

    uuid = "#{str_time}-#{iterator_string}"

    if MailSniffex.DB.get_db() |> CubDB.has_key?(uuid) do
      get_next_id(iterator + 1)
    else
      uuid
    end
  end

  defp unique_id do
    ref_list = :erlang.unique_integer()
    |> :erlang.term_to_binary()
    |> :erlang.md5()
    |> :erlang.bitstring_to_list()

    :lists.flatten Enum.map(ref_list, fn(n)-> :io_lib.format("~2.16.0b", [n]) end)
  end
end
