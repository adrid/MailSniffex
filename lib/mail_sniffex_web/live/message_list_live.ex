defmodule MailSniffexWeb.Live.MessageListLive do
  import MailSniffex.FormatUtils
  use Surface.LiveView, container: {:div, class: "inside-content"}
  alias MailSniffexWeb.Live.MessageListRow
  alias MailSniffexWeb.Live.Pagination
  alias Surface.Components.Form
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Form.Field

  data current_page_count, :integer, default: 0
  data items_per_page, :integer, default: 10

  def mount(_params, _assigns, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MailSniffex.PubSub, "messages")
    end

    db = MailSniffex.DB.get_db()

    {
      :ok,
      socket
      |> assign(:messages, MailSniffex.DB.get_messages())
      |> assign(:count, CubDB.size(db))
      |> assign(:search, %{text: ""})
      |> assign(:current_size, MailSniffex.SizeWatcher.get_current_size())
    }
  end

  def render(assigns) do
    ~H"""
    <div id="message-list-view">
      <Form for={{ :search }} change="change" opts={{ autocomplete: "off" }}>
        <Field name="text">
          <div class="control">
            <TextInput opts={{placeholder: "Search...", "phx-debounce": "500"}} class="input is-primary" value={{ @search.text }} />
          </div>
        </Field>
      </Form>
      <table class="table is-stripped is-fullwidth is-hoverable">
        <thead>
          <tr>
            <th class="unread-column"></th>
            <th>
              From/To
            </th>
            <th>Title</th>
            <th>Received at</th>
          </tr>
        </thead>
        <tbody>
          <MessageListRow
            :for={{{key, message} <- @messages}}
            id={{"message_#{key}"}}
            message={{message}}
            key={{key}}
          />
        </tbody>
      </table>
      <Pagination
        current_page={{@current_page_count}}
        last_item={{List.last(@messages)}}
      />
    </div>
    """
  end

  def handle_info({:messages_cleared}, socket) do
    {
      :noreply,
      socket
      |> assign(:messages, [])
    }
  end

  def handle_info(
        {:message_created, message},
        %{
          assigns: %{current_page_count: page, search: %{text: search_text}}
        } = socket
      )
      when page <= 0 and search_text === "" do
    {
      :noreply,
      socket
      |> update(:messages, fn messages ->
        Enum.take([message | messages], socket.assigns.items_per_page)
      end)
      |> assign(:count, CubDB.size(MailSniffex.DB.get_db()))
    }
  end

  def handle_info({:message_created, message}, socket) do
    {
      :noreply,
      socket
     |> update(:current_page_count, &(&1 + 1))
    }
  end

  def handle_info({:database_cleaned}, socket) do
    {
      :noreply,
      socket
      |> assign(:messages, [])
      |> assign(:current_page_count, 0)
      |> assign(:count, CubDB.size(MailSniffex.DB.get_db()))
    }
  end

  def handle_event("message_click", %{"key" => key}, socket) do
    {:noreply,
     push_redirect(socket,
       to: MailSniffexWeb.Router.Helpers.message_path(socket, :show, key)
     )}
  end

  def handle_event("change", %{"search" => %{"text" => text}}, socket) do
    {:noreply,
     socket
     |> assign(:current_page_count, 0)
     |> assign(:messages, MailSniffex.DB.get_messages([min_key: nil, reverse: true], text))
     |> assign(:search, %{text: text})}
  end

  def handle_event("previous_page", _, socket) do
    first_item_key = case List.first(socket.assigns.messages) do
      {key, _} -> key
      nil -> nil
    end
    {:noreply,
     socket
     |> update(:current_page_count, &(&1 - socket.assigns.items_per_page))
     |> assign(
       :messages,
       MailSniffex.DB.get_messages([min_key: first_item_key, reverse: false], socket.assigns.search.text) |> Enum.reverse()
     )}

  end

  def handle_event("next_page", _, socket) do
    last_item_key = case List.last(socket.assigns.messages) do
      {key, _} -> key
      nil -> nil
    end

    {:noreply,
     socket
     |> update(:current_page_count, &(&1 + socket.assigns.items_per_page))
     |> assign(
       :messages,
       MailSniffex.DB.get_messages([max_key: last_item_key, reverse: true], socket.assigns.search.text)
     )}
  end

end
