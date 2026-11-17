defmodule BraveExTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  setup do
    previous_key = System.get_env("BRAVE_API_KEY")
    System.delete_env("BRAVE_API_KEY")
    previous_config = Application.get_env(:brave_ex, :api_key)
    Application.delete_env(:brave_ex, :api_key)

    on_exit(fn ->
      if previous_key do
        System.put_env("BRAVE_API_KEY", previous_key)
      else
        System.delete_env("BRAVE_API_KEY")
      end

      if previous_config do
        Application.put_env(:brave_ex, :api_key, previous_config)
      else
        Application.delete_env(:brave_ex, :api_key)
      end
    end)

    :ok
  end

  describe "dependency floors" do
    test "resolved HTTP dependencies are outside published advisory ranges" do
      assert_version(:req, ">= 0.6.1 and < 0.8.0")
      assert_version(:mint, ">= 1.10.2 and < 1.12.0")
      assert_version(:hpax, ">= 1.0.4 and < 2.0.0")
    end
  end

  describe "archive responses" do
    test "a zip body is returned unchanged instead of being extracted" do
      zip = zip_archive()

      server =
        start_server(fn request ->
          assert request_target(request) =~ "GET /web/search?"
          response(200, [{"content-type", "application/zip"}], zip)
        end)

      body = BraveEx.web_search("elixir", api_key: "token", base_url: server.base_url)

      assert body == zip
      assert extracted_entry(body) == "EXPANDED-ENTRY"
    end

    test "a zip body reached through a redirect is returned unchanged" do
      zip = zip_archive()

      server =
        start_server(fn request ->
          cond do
            request_target(request) =~ "GET /web/search?" ->
              redirect("/archive.zip")

            request_target(request) =~ "GET /archive.zip" ->
              response(200, [{"content-type", "application/zip"}], zip)

            true ->
              flunk("unexpected request: #{request_target(request)}")
          end
        end)

      body = BraveEx.web_search("elixir", api_key: "token", base_url: server.base_url)

      assert body == zip
      assert extracted_entry(body) == "EXPANDED-ENTRY"
    end
  end

  describe "lenient HTTP/1 framing" do
    test "a leading plus on content-length is rejected" do
      server =
        start_server(fn _request ->
          "HTTP/1.1 200 OK\r\ncontent-type: text/plain\r\ncontent-length: +5\r\nconnection: close\r\n\r\nhello"
        end)

      assert_rejected(fn ->
        BraveEx.web_search("elixir", api_key: "token", base_url: server.base_url)
      end)
    end

    test "a leading plus on a chunk size is rejected" do
      server =
        start_server(fn _request ->
          "HTTP/1.1 200 OK\r\ncontent-type: text/plain\r\ntransfer-encoding: chunked\r\nconnection: close\r\n\r\n+5\r\nhello\r\n0\r\n\r\n"
        end)

      assert_rejected(fn ->
        BraveEx.web_search("elixir", api_key: "token", base_url: server.base_url)
      end)
    end
  end

  describe "search requests" do
    test "json responses stay decoded and each endpoint keeps its path" do
      endpoints = [
        {:web_search, "/web/search"},
        {:image_search, "/images/search"},
        {:video_search, "/videos/search"},
        {:news_search, "/news/search"},
        {:get_query_suggestion, "/suggest/search"},
        {:spellcheck, "/spellcheck/search"}
      ]

      for {fun, path} <- endpoints do
        parent = self()

        server =
          start_server(fn request ->
            send(parent, {:request, request})
            response(200, [{"content-type", "application/json"}], ~s({"type":"search"}))
          end)

        assert apply(BraveEx, fun, ["Elixir lang", [api_key: "token", base_url: server.base_url]]) ==
                 %{"type" => "search"}

        assert_received {:request, request}
        target = request_target(request)
        assert target =~ "GET #{path}?"
        assert target =~ "q=Elixir"
        assert target =~ "lang"
        assert header(request, "x-subscription-token") == "token"
        assert header(request, "accept") == "application/json"
        assert header(request, "user-agent") =~ "BraveEx/"
        assert header(request, "accept-encoding") =~ "gzip"
        stop_server(server)
      end
    end

    test "gzip-encoded json is decompressed and decoded" do
      payload = ~s({"web":{"results":[{"title":"Elixir"}]}})

      server =
        start_server(fn _request ->
          response(
            200,
            [{"content-type", "application/json"}, {"content-encoding", "gzip"}],
            :zlib.gzip(payload)
          )
        end)

      assert BraveEx.web_search("elixir", api_key: "token", base_url: server.base_url) ==
               %{"web" => %{"results" => [%{"title" => "Elixir"}]}}
    end

    test "provided search options are forwarded and omitted options are not invented" do
      parent = self()

      server =
        start_server(fn request ->
          send(parent, {:request, request})
          response(200, [{"content-type", "application/json"}], ~s({"ok":true}))
        end)

      opts = [
        api_key: "token",
        base_url: server.base_url,
        country: "de",
        search_lang: "de",
        ui_lang: "de-DE",
        count: 0,
        offset: 9,
        safesearch: "off",
        freshness: "2022-04-01to2022-07-30",
        text_decorations: 0,
        spellcheck: 0,
        result_filter: ["discussions", "videos"],
        goggles: "https://example.com/goggles",
        units: "metric",
        extra_snippets: true,
        summary: true
      ]

      assert BraveEx.web_search("q", opts) == %{"ok" => true}
      assert_received {:request, request}
      target = URI.decode(request_target(request))

      assert target =~ "country=de"
      assert target =~ "search_lang=de"
      assert target =~ "ui_lang=de-DE"
      assert target =~ "count=0"
      assert target =~ "offset=9"
      assert target =~ "safesearch=off"
      assert target =~ "freshness=2022-04-01to2022-07-30"
      assert target =~ "text_decorations=0"
      assert target =~ "spellcheck=0"
      assert target =~ "result_filter=discussions,videos"
      assert target =~ "goggles="
      assert target =~ "units=metric"
      assert target =~ "extra_snippets=true"
      assert target =~ "summary=true"

      stop_server(server)

      bare =
        start_server(fn request ->
          send(parent, {:bare, request})
          response(200, [{"content-type", "application/json"}], ~s({"ok":true}))
        end)

      assert BraveEx.web_search("only", api_key: "token", base_url: bare.base_url) == %{
               "ok" => true
             }

      assert_received {:bare, bare_request}
      bare_target = URI.decode(request_target(bare_request))
      assert bare_target =~ "q=only"

      for key <- [
            "country=",
            "search_lang=",
            "ui_lang=",
            "count=",
            "offset=",
            "safesearch=",
            "freshness=",
            "result_filter=",
            "goggles=",
            "units=",
            "extra_snippets=",
            "summary="
          ] do
        refute bare_target =~ key
      end
    end

    test "reserved characters in the query stay inside the q parameter" do
      parent = self()

      server =
        start_server(fn request ->
          send(parent, {:request, request})
          response(200, [{"content-type", "application/json"}], ~s({"ok":true}))
        end)

      assert BraveEx.web_search("a&b=c d", api_key: "token", base_url: server.base_url) ==
               %{"ok" => true}

      assert_received {:request, request}
      target = request_target(request)
      assert target =~ "q=a%26b%3Dc"
      refute target =~ "&b="
    end
  end

  describe "api key selection" do
    test "option wins over the environment and the environment wins over config" do
      System.put_env("BRAVE_API_KEY", "env-key")
      Application.put_env(:brave_ex, :api_key, "config-key")
      parent = self()

      server =
        start_server(fn request ->
          send(parent, {:request, request})
          response(200, [{"content-type", "application/json"}], ~s({"ok":true}))
        end)

      assert BraveEx.web_search("q", api_key: "opt-key", base_url: server.base_url) == %{
               "ok" => true
             }

      assert_received {:request, opted}
      assert header(opted, "x-subscription-token") == "opt-key"

      assert BraveEx.web_search("q", base_url: server.base_url) == %{"ok" => true}
      assert_received {:request, from_env}
      assert header(from_env, "x-subscription-token") == "env-key"

      System.delete_env("BRAVE_API_KEY")
      assert BraveEx.web_search("q", base_url: server.base_url) == %{"ok" => true}
      assert_received {:request, from_config}
      assert header(from_config, "x-subscription-token") == "config-key"

      Application.put_env(:other_app, :api_key, "other-key")

      assert BraveEx.web_search("q", app: :other_app, base_url: server.base_url) == %{
               "ok" => true
             }

      assert_received {:request, from_app}
      assert header(from_app, "x-subscription-token") == "other-key"
    end

    test "an explicit empty key is sent and a fully missing key warns" do
      parent = self()

      server =
        start_server(fn request ->
          send(parent, {:request, request})
          response(200, [{"content-type", "application/json"}], ~s({"ok":true}))
        end)

      output =
        capture_io(fn ->
          assert BraveEx.web_search("q", api_key: "", base_url: server.base_url) == %{
                   "ok" => true
                 }
        end)

      assert output == ""
      assert_received {:request, empty_key}
      assert header(empty_key, "x-subscription-token") == ""

      warning =
        capture_io(fn ->
          assert BraveEx.web_search("q", base_url: server.base_url) == %{"ok" => true}
        end)

      assert warning =~ "No API Key specified"
      assert_received {:request, missing_key}
      assert header(missing_key, "x-subscription-token") == "ok"
    end
  end

  describe "failure responses" do
    test "an http error status is returned as the decoded body" do
      server =
        start_server(fn _request ->
          response(404, [{"content-type", "application/json"}], ~s({"error":"missing"}))
        end)

      assert BraveEx.web_search("q", api_key: "token", base_url: server.base_url) ==
               %{"error" => "missing"}
    end

    test "invalid json is not returned as a decoded document" do
      server =
        start_server(fn _request ->
          response(200, [{"content-type", "application/json"}], "{")
        end)

      result =
        try do
          BraveEx.web_search("q", api_key: "token", base_url: server.base_url)
        rescue
          error -> {:raised, error}
        end

      case result do
        {:raised, _error} ->
          :ok

        %Jason.DecodeError{} ->
          :ok

        other ->
          flunk("invalid JSON was treated as a document: #{inspect(other)}")
      end
    end

    test "an unreachable host raises a transport error" do
      assert_raise Req.TransportError, fn ->
        BraveEx.web_search("q", api_key: "token", base_url: "http://127.0.0.1:1", timeout: 200)
      end
    end

    test "a server that closes before responding raises" do
      server =
        start_server(fn _request ->
          :close
        end)

      assert_raise Req.TransportError, fn ->
        BraveEx.web_search("q", api_key: "token", base_url: server.base_url)
      end
    end
  end

  defp assert_version(app, requirement) do
    Application.load(app)

    version =
      app
      |> Application.spec(:vsn)
      |> to_string()

    assert Version.match?(Version.parse!(version), requirement),
           "#{app} #{version} does not match #{requirement}"
  end

  defp assert_rejected(fun) do
    result =
      try do
        {:ok, fun.()}
      rescue
        error -> {:error, error}
      end

    case result do
      {:error, _error} ->
        :ok

      {:ok, value} ->
        flunk("expected the client to reject the response, got: #{inspect(value)}")
    end
  end

  defp zip_archive do
    {:ok, {_name, binary}} =
      :zip.create(~c"archive.zip", [{~c"note.txt", "EXPANDED-ENTRY"}], [:memory])

    binary
  end

  defp extracted_entry(zip) do
    {:ok, [{_name, contents}]} = :zip.extract(zip, [:memory])
    contents
  end

  defp start_server(responder) do
    {:ok, listen} =
      :gen_tcp.listen(0, [
        :binary,
        packet: :raw,
        active: false,
        reuseaddr: true,
        ip: {127, 0, 0, 1}
      ])

    {:ok, port} = :inet.port(listen)

    server =
      spawn_link(fn ->
        accept_loop(listen, responder)
      end)

    handle = %{listen: listen, server: server, base_url: "http://127.0.0.1:#{port}"}
    on_exit(fn -> stop_server(handle) end)
    handle
  end

  defp stop_server(%{listen: listen, server: server}) do
    if Process.alive?(server) do
      Process.unlink(server)
      Process.exit(server, :kill)
    end

    :gen_tcp.close(listen)
  end

  defp accept_loop(listen, responder) do
    case :gen_tcp.accept(listen, 1_000) do
      {:ok, socket} ->
        request = read_request(socket, "")

        case responder.(request) do
          :close ->
            :gen_tcp.close(socket)

          response ->
            :ok = :gen_tcp.send(socket, response)
            :gen_tcp.close(socket)
        end

        accept_loop(listen, responder)

      {:error, :timeout} ->
        accept_loop(listen, responder)

      {:error, _reason} ->
        :ok
    end
  end

  defp read_request(socket, acc) do
    if String.contains?(acc, "\r\n\r\n") do
      acc
    else
      {:ok, data} = :gen_tcp.recv(socket, 0, 5_000)
      read_request(socket, acc <> data)
    end
  end

  defp response(status, headers, body) do
    header_block =
      Enum.map(headers, fn {name, value} ->
        [name, ": ", value, "\r\n"]
      end)

    [
      "HTTP/1.1 #{status} OK\r\n",
      header_block,
      "content-length: #{byte_size(body)}\r\n",
      "connection: close\r\n",
      "\r\n",
      body
    ]
  end

  defp redirect(location) do
    """
    HTTP/1.1 302 Found\r
    location: #{location}\r
    content-length: 0\r
    connection: close\r
    \r
    \
    """
  end

  defp request_target(request) do
    request
    |> String.split("\r\n", parts: 2)
    |> hd()
  end

  defp header(request, name) do
    request
    |> String.split("\r\n")
    |> Enum.find_value(fn line ->
      case String.split(line, ":", parts: 2) do
        [key, value] ->
          if String.downcase(String.trim(key)) == name, do: String.trim(value)

        _ ->
          nil
      end
    end)
  end
end
