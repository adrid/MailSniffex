defmodule MailSniffexWeb.Live.ConfirmModal do
  use Surface.LiveComponent

  prop title, :string, required: true
  prop confirmEvent, :event, required: true

  data show, :boolean, default: false


  def render(assigns) do
    ~H"""
    <div class={{ "modal", "is-active": @show }}>
      <div class="modal-background" :on-click="hide"></div>
      <div class="modal-card">
        <header class="modal-card-head">
          <p class="modal-card-title">{{ @title }}</p>
          <button class="delete" aria-label="close" :on-click="hide"></button>
        </header>
        <section class="modal-card-body">
          <slot/>
        </section>
        <footer class="modal-card-foot" style="justify-content: flex-end">
          <button class="button is-success" :on-click={{@confirmEvent}}>Yes</button>
          <button class="button" :on-click="hide">Cancel</button>
        </footer>
      </div>
    </div>
    """
  end

  def show(dialog_id) do
    send_update(__MODULE__, id: dialog_id, show: true)
  end

  def hide(dialog_id) do
    send_update(__MODULE__, id: dialog_id, show: false)
  end

  def handle_event("show", _, socket) do
    {:noreply, assign(socket, show: true)}
  end

  def handle_event("hide", _, socket) do
    {:noreply, assign(socket, show: false)}
  end
end
