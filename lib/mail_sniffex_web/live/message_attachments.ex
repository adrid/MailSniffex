defmodule MailSniffexWeb.Live.MessageAttachments do
  alias MailSniffexWeb.Router.Helpers, as: Routes
  alias Surface.Components.Link
  use Surface.Component

  prop attachments, :any, required: true
  prop inline_files, :any, required: true
  prop message_key, :string, required: true

  @spec render(any) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
      <div :if={{@attachments}}>
        Attachments:
        <div :for={{{attachment, index} <- Enum.with_index(@attachments)}}>
        <Link
          opts={{target: "_blank"}}
          to={{Routes.mail_path(assigns.socket, :download, message_key: @message_key, file_key: index, type: "attachments")}}
        >
          {{attachment.name}}
        </Link>
      </div>
      </div>
      <hr/>
      <div :if={{@inline_files}}>
        Embeded files:
        <div :if={{@inline_files !== nil}} :for={{{attachment, index} <- Enum.with_index(@inline_files)}}>
          <Link
            opts={{target: "_blank"}}
            to={{Routes.mail_path(assigns.socket, :download, message_key: @message_key, file_key: index, type: "inline_files")}}
          >
            {{attachment.name}}
          </Link>
        </div>
      </div>
    """
  end
end
