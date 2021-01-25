defmodule MailSniffex.SizeWatcher do
  use GenStateMachine, callback_mode: [:handle_event_function]

  @data_path Application.compile_env(:mail_sniffex, :data_path)

  def init(_state) do
    {:ok, :waiting, %{current_size: calculate_size(), update_expected: false}}
  end

  def start_link(_opts) do
    GenStateMachine.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_size_limit() do
    Application.get_env(:mail_sniffex, :size_limit) |> MailSniffex.FormatUtils.get_bytes()
  end

  def handle_event({:call, from}, :get_current_size, state, %{current_size: current_size} = data) do
    {:next_state, state, data, [{:reply, from, current_size}]}
  end

  def handle_event(:cast, :request_size_check, :waiting, data) do
    {:next_state, :calculating, data, [{:next_event, :internal, :calculate}]}
  end

  def handle_event(:cast, :request_size_check, state, data) do
    {:keep_state, %{data | update_expected: true}}
  end

  def handle_event(:internal, :calculate, state, data) do
    size = calculate_size()
    Phoenix.PubSub.broadcast(MailSniffex.PubSub, "data_size_changes", {:size_updated, %{size: size}})
    if size > get_size_limit() do
      {:next_state, :removing_old_data, %{data | current_size: size}, [{:next_event, :internal, :remove_old_data}]}
    else
      state_after_calculating(data, size)
    end
  end

  def handle_event(:internal, :remove_old_data, :removing_old_data, %{current_size: current_size} = data) do
    MailSniffex.DB.remove_old(current_size)
    size = calculate_size()
    Phoenix.PubSub.broadcast(MailSniffex.PubSub, "data_size_changes", {:size_updated, %{size: size}})
    state_after_calculating(data, size)
  end

  def get_current_size(), do: GenStateMachine.call(__MODULE__, :get_current_size)

  def request_current_size(), do: GenStateMachine.cast(__MODULE__, :request_size_check)

  defp state_after_calculating(data, size) do
    if data.update_expected do
      {:next_state, :calculating, %{data | current_size: size, update_expected: false}, [{:next_event, :internal, :calculate}]}
    else
      {:next_state, :waiting, %{data | current_size: size}}
    end
  end

  defp calculate_size() do
    :filelib.fold_files(
      @data_path,
      '.*',
      true,
      fn file_name, acc ->
        acc + :filelib.file_size(file_name)
      end,
      0
    )
  end

end
