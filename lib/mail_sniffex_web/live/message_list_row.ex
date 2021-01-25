defmodule MailSniffexWeb.Live.MessageListRow do
  import MailSniffex.FormatUtils
  use Surface.Component

  prop key, :string, required: true
  prop message, :map, required: true

  def render(assigns) do
    from = MailSniffex.AddressParser.parse_address(assigns.message.headers["From"])
    to = MailSniffex.AddressParser.parse_address(assigns.message.headers["To"])

    ~H"""
      <tr class="is-clickable" phx-click="message_click" phx-value-key={{@key}}>
        <th class={{unread: @message.unread}}>
        </th>
        <td>
          <div>
            <strong>{{from.email}}</strong>
          </div>
          <div>
            {{ to.email }}
          </div>
        </td>
        <td>
          {{@message.headers["Subject"]}}
        </td>
        <td>
          {{ format_datetime(@message.datetime)}}
        </td>
      </tr>
    """
  end
end
