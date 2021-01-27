defmodule MailSniffexWeb.Live.Header do
  use Surface.LiveView
  alias Surface.Components.LiveRedirect
  alias MailSniffexWeb.Live.ConfirmModal

  @env Application.compile_env(:mail_sniffex, :environment)

  def mount(_params, _assigns, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MailSniffex.PubSub, "messages")
      Phoenix.PubSub.subscribe(MailSniffex.PubSub, "data_size_changes")
    end

    db = MailSniffex.DB.get_db()

    {
      :ok,
      socket
      |> assign(:count, CubDB.size(db))
      |> assign(:current_size, MailSniffex.SizeWatcher.get_current_size())
    }
  end

  def render(assigns) do
    limit = MailSniffex.SizeWatcher.get_size_limit()
    env = @env
    ~H"""
      <header phx-hook="Header" class="header" id="header">
        <div class="content">
          <div class="columns">
            <div class="column">
              <LiveRedirect class="button is-primary" to="/">MailSniffex | Inbox: {{ @count }}</LiveRedirect>
              <a :if={{env === :dev}} class="button" href="#" :on-click="send_test_btn_click">Send test</a>
            </div>
            <div class="column has-text-centered">
              <div class="tags has-addons is-inline-block">
                <span class="tag is-dark is-large">
                  {{Float.to_string(@current_size |> bytes_to_meagabytes(), decimals: 2)}} MB
                </span>
                <span class="tag is-primary is-large">
                  {{Float.to_string(limit |> bytes_to_meagabytes(), decimals: 2)}} MB
                </span>
              </div>
              <a href="#" class="button is-inline-block" :on-click="clear_btn_click">Clear inbox</a>
            </div>
            <div class="column has-text-right">
              <a href="https://github.com/adrid/MailSniffex" target="_blank" class="button is-text">
                <span class="icon">
                  <img src="/images/github.png">
                </span>
                <span>GitHub</span>
              </a>
            </div>
          </div>
        </div>
      </header>
      <ConfirmModal id="clear-confirm" title="Confirm action" confirmEvent="clear_mails">
        Do you really want to delete all mails?
      </ConfirmModal>
    """
  end

  def bytes_to_meagabytes (data) do
    data / 1000 / 1000
  end

  def handle_event("clear_btn_click", _, socket) do
    ConfirmModal.show("clear-confirm")
    {:noreply, socket}
  end

  def handle_event("clear_mails", _, socket) do
    MailSniffex.DB.clean_db()
    MailSniffex.SizeWatcher.request_current_size()
    Phoenix.PubSub.broadcast(MailSniffex.PubSub, "messages", {:messages_cleared})
    ConfirmModal.hide("clear-confirm")
    {:noreply, socket}
  end

  def handle_event("send_test_btn_click", _, socket) do
    :gen_smtp_client.send_blocking(
      {"from_test@example.com", ["to_test@example.com"],
       File.read!("test/fixtures/plain.eml") |> String.to_charlist()},
      [{:relay, "localhost"}, {:port, 2525}, {:hostname, "localhost"}]
    )

    :gen_smtp_client.send_blocking(
      {"from_test@example.com", ["to_test@example.com"],
       File.read!("test/fixtures/html.eml") |> String.to_charlist()},
      [{:relay, "localhost"}, {:port, 2525}, {:hostname, "localhost"}]
    )

    {:noreply, socket}
  end

  def handle_info({:message_created, message}, socket) do
    {
      :noreply,
      socket
      |> send_push_notifcation(message)
      |> assign(:count, CubDB.size(MailSniffex.DB.get_db()))
    }
  end

  def handle_info({:size_updated, %{size: size}}, socket) do
    {
      :noreply,
      socket
      |> assign(:current_size, size)
    }
  end

  def handle_info({:messages_cleared}, socket) do
    {
      :noreply,
      socket
      |> assign(:count, CubDB.size(MailSniffex.DB.get_db()))
    }
  end

  defp send_push_notifcation(socket, {key, message}) do
    push_event(socket, "message_created", %{
      subject: message.headers["Subject"],
      from: message.headers["From"],
      url: MailSniffexWeb.Router.Helpers.message_url(socket, :show, key)
    })
  end

end
