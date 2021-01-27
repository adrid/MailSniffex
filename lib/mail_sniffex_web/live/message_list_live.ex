defmodule MailSniffexWeb.Live.MessageListLive do
  import MailSniffex.FormatUtils
  use Surface.LiveView, container: {:div, class: "inside-content"}
  alias MailSniffexWeb.Live.MessageListRow
  alias MailSniffexWeb.Live.Pagination
  alias Surface.Components.Form
  alias Surface.Components.Form.TextInput
  alias Surface.Components.Form.Field

  data current_page_count, :integer, default: 0

  def mount(_params, _assigns, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(MailSniffex.PubSub, "messages")
    end

    db = MailSniffex.DB.get_db()
    items_per_page = 10
    search_options = %{items_per_page: items_per_page}

    {
      :ok,
      socket
      |> assign(:items_per_page, items_per_page)
      |> assign(:messages, MailSniffex.DB.get_messages(search_options))
      |> assign(:count, CubDB.size(db))
      |> assign(:search_form, %{text: ""})
      |> assign(:search_options, search_options)
      |> assign(:current_size, MailSniffex.SizeWatcher.get_current_size())
    }
  end

  def render(assigns) do
    ~H"""
    <div id="message-list-view">
      <div class="is-flex">
        <div class="is-flex-grow-1">
        <Form for={{ :search_form }} change="change" submit="change" opts={{ autocomplete: "off" }}>
          <Field name="text">
            <div class="control">
              <TextInput opts={{placeholder: "Search...", "phx-debounce": "500"}} class="input is-primary" value={{ @search_form.text }} />
            </div>
          </Field>
        </Form>
        </div>
        <div>
          <Pagination
            current_page={{@current_page_count}}
            last_item={{List.last(@messages)}}
            search_options={{assigns.search_options}}
          />
        </div>
      </div>
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
        search_options={{assigns.search_options}}
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
          assigns: %{current_page_count: page, search_form: %{text: search_text}}
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

  def handle_event("change", %{"search_form" => %{"text" => text}}, socket) do
    search_options = %{select: [min_key: nil, reverse: true], search_text: text, items_per_page: socket.assigns.items_per_page}
    {:noreply,
     socket
     |> assign(:current_page_count, 0)
     |> assign(:search_form, %{text: text})
     |> assign(:search_options, search_options)
     |> assign(:messages, MailSniffex.DB.get_messages(search_options))
    }
  end

  def handle_event("previous_page", _, socket) do
    first_item_key = case List.first(socket.assigns.messages) do
      {key, _} -> key
      nil -> nil
    end
    search_options = %{select: [min_key: first_item_key, reverse: false], search_text: socket.assigns.search_form.text, items_per_page: socket.assigns.items_per_page}
    {:noreply,
     socket
     |> update(:current_page_count, &(&1 - socket.assigns.items_per_page))
     |> assign(:search_options, search_options)
     |> assign(
       :messages,
       MailSniffex.DB.get_messages(search_options) |> Enum.reverse()
     )}

  end

  def handle_event("next_page", _, socket) do
    last_item_key = case List.last(socket.assigns.messages) do
      {key, _} -> key
      nil -> nil
    end

    search_options = %{select: [max_key: last_item_key, reverse: true], search_text: socket.assigns.search_form.text, items_per_page: socket.assigns.items_per_page}

    {:noreply,
     socket
     |> update(:current_page_count, &(&1 + socket.assigns.items_per_page))
     |> assign(
       :messages,
       MailSniffex.DB.get_messages(search_options)
     )}
  end

end
