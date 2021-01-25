defmodule MailSniffexWeb.Live.MessageLive do
  use Surface.LiveView, container: {:div, class: "inside-content"}
  alias MailSniffexWeb.Live.MessageHeader
  alias MailSniffexWeb.Live.MessageAttachments
  alias MailSniffexWeb.Router.Helpers, as: Routes

  @data_path Application.compile_env(:mail_sniffex, :data_path)

  data tab, :integer, default: 1

  def mount(%{"message" => message_key}, _assigns, socket) do
    db = MailSniffex.DB.get_db()

    message =
      db
      |> CubDB.get(message_key)

    if message do
      db
      |> CubDB.put(message_key, %{message | unread: false})
    end

    source =
      message_key
      |> source_content()

    message_data = if source !== nil do
      source
      |> :mimemail.decode()
      |> MailSniffex.MailSourceParser.parse()
    else
      nil
    end

    {
      :ok,
      socket
      |> assign(:message, message)
      |> assign(:message_key, message_key)
      |> assign(:message_data, message_data)
      |> assign(:source, source)
    }
  end

  def render(%{message: message} = assigns) when message === nil do
    ~H"""
     <section class="hero is-danger" :if={{@message === nil}}>
        <div class="hero-body">
          <div class="hero-container">
            <h1>Email doesn't exists</h1>
          </div>
        </div>
      </section>
    """
  end

  def render(assigns) do
    ~H"""
      <div class="inside-content is-flex is-flex-direction-column">
        <div class="">
        <div class="hero-container">
          <MessageHeader id="message_header" headers={{@message.headers}}/>
        </div>
        <div class="tabs is-centered is-toggle">
          <ul>
            <li id="html-tab-btn" class={{"is-active": @tab === 1}} phx-click="tab_click" phx-value-key={{1}}><a>HTML</a></li>
            <li id="plain-text-tab-btn" class={{"is-active": @tab === 2}} phx-click="tab_click" phx-value-key={{2}}><a>Plain text</a></li>
            <li id="source-tab-btn" class={{"is-active": @tab === 3}} phx-click="tab_click" phx-value-key={{3}}><a>Source</a></li>
            <li id="attachments-tab-btn" class={{"is-active": @tab === 4}} phx-click="tab_click" phx-value-key={{4}}><a>Attachments ({{count_attachments(@message_data.body["attachments"])}})</a></li>
          </ul>
        </div>
        </div>
        <iframe
          :if={{@tab === 1}}
          id="myIframe"
          class="has-background-white is-flex-grow-1"
          width="100%"
          height="100%"
          src="{{ Routes.mail_url(assigns.socket, :iframe, message_key: @message_key) }}"></iframe>
        <pre :if={{@tab === 2}}>{{text_content(@message_data)}}</pre>
        <pre :if={{@tab === 3}}>{{@source}}</pre>
        <MessageAttachments
          :if={{@tab === 4}}
          message_key={{@message_key}}
          attachments={{@message_data.body["attachments"]}}
          inline_files={{@message_data.body["inline_files"]}}/>
      </div>
    """
  end

  defp count_attachments(data) do
    case data do
      nil -> 0
      list -> list |> length()
    end
  end
  defp text_content(message_data) do
    message_data.body["plain"]
  end

  defp source_content(key) do
    path =
      @data_path
      |> Path.join("source")
      |> Path.join(key)

    case File.read(path) do
      {:ok, content} -> content |> :erlang.binary_to_term()
      _ -> nil
    end
  end

  def handle_event("tab_click", %{"key" => key}, socket) do
    {val, _} = Integer.parse(key)
    {:noreply, socket |> assign(:tab, val)}
  end
end
