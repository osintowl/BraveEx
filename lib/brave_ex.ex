defmodule BraveEx do
  @moduledoc """
  A client library for interacting with the Brave Search API. 
  """
  @base_url "https://api.search.brave.com/res/v1"
  @default_timeout 10_000
  @user_agent "BraveEx/0.1 (Elixir; +https://github.com/osintowl/BraveEx) Mozilla/5.0 (compatible; BraveEx/0.1)"

  @doc """
  Does a Web search as default with Brave api search.

  ## Parameters
    - q: The query being passed
        - Default:  None
        - Required: True
    - opts: Keyword list of options
    
        - `:base_url` - The base url for the API, this can be changed for versions, or if needed in the future.
            - Default: #{@base_url}
            - Required: true

        - `:timeout`  - Request timeout in milliseconds
            - Default: #{@default_timeout}
            - Required: false

        - `:api_key`  - The API key for your usage.
            - Default: Default is pulled from ENV for BRAVE_API_KEY or you can set the :app below to use in config
            - Required: true

        - `:app` - The application name to use when fetching the API key from config
            - Default: :brave_ex
            - Required: false

        - `:country`  - The search query country, where the results come from. The country string is limited to 2 character country codes of supported countries.
            - Default:  US
            - Required: false

        - `:search_lang` - The search language preference.
            - Default:  en
            - Required: false

        - `:ui_lang`  - User interface language preferred in response. Usually of the format ‘<language_code>-<country_code>’.
            - Default:  en-US
            - Required: false

        - `:count` - The number of search results returned in response. The maximum is 20. The actual number delivered may be less than requested. Combine this parameter with offset to paginate search results.
            - Default:  20
            - Required: false

        - `:offset`  - The zero based offset that indicates number of search results per page (count) to skip before returning the result. The maximum is 9. The actual number delivered may be less than requested based on the query. In order to paginate results use this parameter together with count. For example, if your user interface displays 20 search results per page, set count to 20 and offset to 0 to show the first page of results. To get subsequent pages, increment offset by 1 (e.g. 0, 1, 2). The results may overlap across multiple pages.
            - Default:  0
            - Required: false

        - `:safesearch`  - Filters search results for adult content. Options are off, moderate, and IgnoreFileStrict
            - Default:  moderate
            - Required: false

        - `:freshness` - Filters search results by when they were discovered. pd will return last 24 hours, pw will return the last 7 days, pm will return the last 31 days, py will return the last 365 days timeframe is also supported by specifying the date range e.g. 2022-04-01to2022-07-30 . 
            - Default:  no filtering
            - Required: false


        - `:text_decorations` - Whether display strings (e.g. result snippets) should include decoration markers (e.g. highlighting characters).
            - Default: 1
            - Required: false

        - `:spellcheck` - Whether to spellcheck provided query. If the spellchecker is enabled, the modified query is always used for search. The modified query can be found in altered key from the query response model.
            - Default:  1
            - Required: false
        
        - `:result_filter` - A comma delimited string of result types to include in the search response. Not specifying this parameter will return back all result types in search response where data is available and a plan with the corresponding option is subscribed. The response always includes query and type to identify any query modifications and response type respectively. Available result filter values are: discussions, faq, infobox, news, query, summarizer, videos, web, locations
            - Default:  No default
            - Required: false
        
        - `:goggles`  - Goggles act as a custom re-ranking on top of Brave’s search index. The parameter supports both a url where the Goggle is hosted or the definition of the goggle.
            - Default:  No default
            - Required: false
        
        - `:units`  - The measurement units. If not provided, units are derived from search country. Possible values are metric and imperial. 
            - Default:  No default
            - Required: false
        
        - `:extra_snippets`  - A snippet is an excerpt from a page you get as a result of the query, and extra_snippets allow you to get up to 5 additional, alternative excerpts. This is only available in the following tiers Free AI, Base AI, Pro AI, Pro Data, and custom plans. 
            - Default:  No default
            - Required: false

        - `:summary`  - This parameter enables summary key generation in web search results. This is required for summarizer to be enabled.
            - Default:  No default
            - Required: false
        
  """

  def web_search(query, opts \\ []) do
      # First I start by building the params that are sent into request
      params = build_search_params(query, opts)
      # I want to build non Brave params individually outside of space, so apttern match on the results from the get_client_config function
      %{base_url: base_url, timeout: timeout, api_key: api_key} = get_client_config(opts)

      make_request(base_url, "/web/search", params, api_key, timeout)
  
  end

  def image_search(query, opts \\ []) do
      # First I start by building the params that are sent into request
      params = build_search_params(query, opts)
      # I want to build non Brave params individually outside of space, so apttern match on the results from the get_client_config function
      %{base_url: base_url, timeout: timeout, api_key: api_key} = get_client_config(opts)

      make_request(base_url, "/images/search", params, api_key, timeout)
  
  end

  def video_search(query, opts \\ []) do
      # First I start by building the params that are sent into request
      params = build_search_params(query, opts)
      # I want to build non Brave params individually outside of space, so apttern match on the results from the get_client_config function
      %{base_url: base_url, timeout: timeout, api_key: api_key} = get_client_config(opts)

      make_request(base_url, "/videos/search", params, api_key, timeout)
  end

  def news_search(query, opts \\ []) do
      # First I start by building the params that are sent into request
      params = build_search_params(query, opts)
      # I want to build non Brave params individually outside of space, so apttern match on the results from the get_client_config function
      %{base_url: base_url, timeout: timeout, api_key: api_key} = get_client_config(opts)

      make_request(base_url, "/news/search", params, api_key, timeout)
  end

  def get_query_suggestion(query, opts \\ []) do
      # First I start by building the params that are sent into request
      params = build_search_params(query, opts)
      # I want to build non Brave params individually outside of space, so apttern match on the results from the get_client_config function
      %{base_url: base_url, timeout: timeout, api_key: api_key} = get_client_config(opts)

      make_request(base_url, "/suggest/search", params, api_key, timeout)
  end

  def spellcheck(query, opts \\ []) do
      # First I start by building the params that are sent into request
      params = build_search_params(query, opts)
      # I want to build non Brave params individually outside of space, so apttern match on the results from the get_client_config function
      %{base_url: base_url, timeout: timeout, api_key: api_key} = get_client_config(opts)

      make_request(base_url, "/spellcheck/search", params, api_key, timeout)
  end


  defp make_request(base_url, search_path, params, api_key, timeout) do
      response = Req.get!(
          "#{base_url}#{search_path}",
          params: params,
          headers: [
            {"Accept", "application/json"},
            {"Accept-Encoding", "gzip"},
            {"X-Subscription-Token", api_key}
          ],
          compressed: true, 
          user_agent: @user_agent,
          connect_options: [timeout: timeout]
        )

        response.body

  end
  
  defp build_search_params(query, opts) do
      []
      |> Keyword.put(:q, query)
      |> add_param(:country, opts)
      |> add_param(:search_lang, opts)
      |> add_param(:ui_lang, opts)
      |> add_param(:count, opts)
      |> add_param(:offset, opts)
      |> add_param(:safesearch, opts)
      |> add_param(:freshness, opts)
      |> add_param(:text_decorations, opts)
      |> add_param(:spellcheck, opts)
      |> add_param(:result_filter, opts)
      |> add_param(:goggles, opts)
      |> add_param(:units, opts)
      |> add_param(:extra_snippets, opts)
      |> add_param(:summary, opts)
  end

  defp add_param(params, key, opts, opt_key \\ nil) do
    opt_key = opt_key || key
    case Keyword.get(opts, opt_key) do
      nil -> params
      value when is_list(value) -> Keyword.put(params, key, Enum.join(value, ","))
      value -> Keyword.put(params, key, value)
    end
  end

  defp get_api_key(opts, app) do
    cond do
      # Check opts first
      Keyword.has_key?(opts, :api_key) ->
        Keyword.get(opts, :api_key)

      # Then check environment variable
      api_key = System.get_env("BRAVE_API_KEY") ->
        api_key

      # Finally check application config
      api_key = Application.get_env(app, :api_key) ->
        api_key

      # If none found, return nil or raise an error (your choice)
      true ->
        IO.puts("No API Key specified in opt, environment, or config")  # or raise "No API key found in opts, environment, or config"
    end
  end

  defp get_client_config(opts) do
    base_url = Keyword.get(opts, :base_url, @base_url)
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    app = Keyword.get(opts, :app, :brave_ex)
    api_key = get_api_key(opts, app)
    %{base_url: base_url, timeout: timeout, api_key: api_key}
  end
end      
  
