defmodule MailSniffex.AddressParser do
  def parse_addresses(addresses) when is_binary(addresses) do
    address_list = String.split(addresses, ",")
    parse_addresses(address_list, [])
  end

  def parse_addresses([], parsed) do
    parsed
  end

  def parse_addresses([address | addresses], parsed) do
    address = String.strip(address)
    new_parsed = [parse_address(address) | parsed]
    parse_addresses(addresses, new_parsed)
  end

  def parse_address(address) do
    parts = String.split(address, "<")
    case length(parts) do
      1 ->
        %{email: address}

      2 ->
        email =
          List.last(parts)
          |> String.split(">")
          |> hd()
          |> String.strip()

        name = hd(parts) |> String.strip()
        %{name: name, email: email}
    end
  end
end
