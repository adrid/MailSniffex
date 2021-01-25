defmodule MailSniffex.MailSourceParser do
  def parse(data) do
    {body, headers} =
      parse_data(data)
      |> Map.split(["attachments", "html", "plain", "inline_files"])

    %{body: body, headers: headers}
  end

  defp parse_data({"multipart", _subtype_name, mail_meta, _, body}) do
    parse_bodies(body)
    |> Map.merge(extract_meta(mail_meta))
  end

  defp parse_data({"text", subtype_name, mail_meta, _, body})
     when subtype_name === "html" do
    metadata = extract_meta(mail_meta)
    %{"html" => body} |> Map.merge(metadata)
  end

  defp parse_data({"text", subtype_name, mail_meta, %{disposition: disposition}, body})
      when subtype_name === "plain" and disposition === "inline"  do
    metadata = extract_meta(mail_meta)
    %{"plain" => body} |> Map.merge(metadata)
  end

  defp parse_data(
        {_, _, mail_meta, %{disposition: disposition, disposition_params: params}, body}
      )
      when disposition === "inline" do
    file_params = extract_meta(params)
    metadata = extract_meta(mail_meta)

    {:files, "inline_files",
     %{name: file_params["filename"], id: metadata["Content-ID"], body: body}}
  end

  defp parse_data(
        {_, _, mail_meta, %{disposition: disposition, disposition_params: params}, body}
      )
      when disposition === "attachment" do
    file_params = extract_meta(params)
    metadata = extract_meta(mail_meta)

    {:files, "attachments",
     %{name: file_params["filename"], id: metadata["Content-ID"], body: body}}
  end

  defp parse_bodies([], collected), do: collected

  defp parse_bodies([body | bodies], collected \\ %{}) do
    next =
      case parse_data(body) do
        {:files, type, details} ->
          data = get_in(collected, [Access.key(type, [])]) ++ [details]
          put_in(collected, [type], data)

        data ->
          Map.merge(collected, data)
      end

    parse_bodies(bodies, next)
  end

  defp extract_meta(mail_meta) do
    data =
      Enum.reduce(:proplists.get_keys(mail_meta), %{}, fn field, data ->
        value = :proplists.get_value(field, mail_meta)
        Map.put(data, field, value)
      end)

    Map.drop(data, ["Content-Type", "Content-Transfer-Encoding"])
  end
end
