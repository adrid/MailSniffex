defmodule MailSniffexWeb.Live.MessageHeader do
  use Surface.LiveComponent
  prop headers, :map, required: true

  def render(assigns) do
    from = MailSniffex.AddressParser.parse_address(assigns.headers["From"])
    to = MailSniffex.AddressParser.parse_address(assigns.headers["To"])

    ~H"""
      <div>
        <dl :if={{@headers}}>
          <dt>Subject:</dt>
          <dd>{{@headers["Subject"]}}</dd>

          <dt>From:</dt>
          <dd><span class="tag is-white is-rounded is-medium">{{from.email}}</span></dd>

          <dt>To:</dt>
          <dd>
            <span class="tag is-white is-rounded is-medium">{{to.email}}</span>
          </dd>
        </dl>
      </div>
    """
  end
end
