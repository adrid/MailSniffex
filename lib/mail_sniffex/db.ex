defmodule MailSniffex.DB do
  use GenServer
  @data_path Application.compile_env(:mail_sniffex, :data_path)

  def init(_state) do
    {:ok, db} = CubDB.start_link(data_dir: @data_path, auto_compact: true, name: :db)
    {:ok, %{database: db}}
  end

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_db(), do: GenServer.call(__MODULE__, {:get_db})

  def clean_db(), do: GenServer.call(__MODULE__, {:clean_db})
  def remove_old(current_size), do: GenServer.call(__MODULE__, {:remove_old, current_size})

  def handle_call({:get_db}, _from, %{database: db} = state) do
    {:reply, db, state}
  end

  def handle_call({:clean_db}, _from, %{database: db} = state) do
    {:ok, keys} =
      CubDB.select(db,
        pipe: [
          map: fn {key, _value} -> key end
        ]
      )

    CubDB.delete_multi(db, keys)
    :file.del_dir_r(@data_path |> Path.join("source"))
    {:reply, db, state}
  end

  def handle_call({:remove_old, current_size}, _from, %{database: db} = state) do
    {:ok, agent} = Agent.start_link(fn -> current_size end)
    {:ok, keys} =
      CubDB.select(db,
        pipe: [
          take_while: fn {key, _value} ->
            filename = @data_path
            |> Path.join("source")
            |> Path.join(key)

            Agent.update(agent, &(&1 - :filelib.file_size(filename) ))
            :file.delete(filename)
            Agent.get(agent, &(&1)) > MailSniffex.SizeWatcher.get_size_limit()
          end,
          map: fn {key, _value} -> key end
        ],
      )
    Agent.stop(agent)
    CubDB.delete_multi(db, keys)
    {:reply, db, state}
  end

  def get_messages(options) do
    defaults = %{
      select: [min_key: nil, reverse: true],
      search_text: "",
      items_per_page: 10
    }
    options = Map.merge(defaults, options)

    select_options = [
      max_key_inclusive: false,
      min_key_inclusive: false,
      pipe: [
        filter: fn {_key, el} ->
          if options.search_text === "" do
            true
          else
            el.headers["Subject"] <> el.headers["From"] <> el.headers["To"]
            |> String.downcase()
            |> String.contains?(options.search_text |> String.downcase())
          end
        end,
        take: options.items_per_page
      ],
    ] |> Keyword.merge(options.select)

    db = MailSniffex.DB.get_db()

    {:ok, messages} =
      db
      |> CubDB.select(select_options)

    messages
  end
end
