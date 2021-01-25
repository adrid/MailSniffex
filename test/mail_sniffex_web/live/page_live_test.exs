defmodule MailSniffexWeb.PageLiveTest do
  use MailSniffexWeb.ConnCase

  import Phoenix.ConnTest
  import Phoenix.LiveViewTest

  test "empty list returns 200", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Inbox: 0"
  end

  test "HTML mail test", %{conn: conn} do
    :gen_smtp_client.send_blocking(
      {"from_test@example.com", ["to_test@example.com"],
       File.read!("test/fixtures/html.eml") |> String.to_charlist()},
      [{:relay, "localhost"}, {:port, 2525}, {:hostname, "localhost"}]
    )

    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Inbox: 1"

    {:ok, view, _html} = live(conn)
    row = view |> element("tbody tr.is-clickable:first-child()")
    assert row |> render() =~ "HTML Mail"

    {:ok, view, _html} = row |> render_click() |> follow_redirect(conn)

    assert view |> element(".tabs ul li#plain-text-tab-btn") |> render_click() =~ "<pre></pre>"

    assert view |> element(".tabs ul li#source-tab-btn") |> render_click() =~
             "Message-ID: &lt;c569b0933c393e8e2877120291cbf713@example.com&gt;"

    refute view |> element(".tabs ul li#attachments-tab-btn") |> render_click() =~ "Attachments:"
  end

  test "plain with attachments test", %{conn: conn} do
    :gen_smtp_client.send_blocking(
      {"from_test@example.com", ["to_test@example.com"],
       File.read!("test/fixtures/plain.eml") |> String.to_charlist()},
      [{:relay, "localhost"}, {:port, 2525}, {:hostname, "localhost"}]
    )

    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Inbox: 1"
  end
end
