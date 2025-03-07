# BraveEx

**BraveEx** is an Elixir client library for interacting with the [Brave Search API](https://api.search.brave.com). It provides a simple and consistent interface to perform web, image, video, news searches, fetch query suggestions, and perform spellchecks—all using a unified API.

## Features

- **Web Search:** Quickly perform standard web searches.
- **Image Search:** Retrieve image search results.
- **Video Search:** Get video search results.
- **News Search:** Access the latest news results.
- **Query Suggestions & Spellcheck:** Enhance your search experience with suggestions and spellchecking.

## Installation

Add `brave_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:brave_ex, "~> 0.1.0"}
  ]
end
```

Then, fetch the dependencies by running:

```sh
mix deps.get
```

## Configuration

BraveEx requires an API key for authenticating with the Brave Search API. The API key is determined via the following priority:

1. Passed in explicitly as an option (`:api_key`).
2. Pulled from the environment variable `BRAVE_API_KEY`.
3. Retrieved from your application configuration (default app key is `:brave_ex`).

Make sure your API key is set in one of these ways before using the library.

## Usage

All search functions accept a query string and an optional keyword list of parameters to customize the search request.

### Web Search Example

```elixir
iex> BraveEx.web_search("Elixir programming")
```

### Other Search Functions

- **Image Search**

  ```elixir
  iex> BraveEx.image_search("Elixir logo")
  ```

- **Video Search**

  ```elixir
  iex> BraveEx.video_search("Elixir tutorial")
  ```

- **News Search**

  ```elixir
  iex> BraveEx.news_search("Elixir release")
  ```

- **Query Suggestions**

  ```elixir
  iex> BraveEx.get_query_suggestion("Elixir")
  ```

- **Spellcheck**

  ```elixir
  iex> BraveEx.spellcheck("Elixr")
  ```

## Options

Each search function accepts an optional keyword list that lets you override default values and customize your request. Some of the common options include:

- **`:base_url`**  
  The base URL for the Brave API.  
  _Default:_ `https://api.search.brave.com/res/v1`

- **`:timeout`**  
  Request timeout in milliseconds.  
  _Default:_ `10_000`

- **`:api_key`**  
  Your Brave API key. If not provided, it will be fetched from the environment or config.

- **`:app`**  
  The application name used when fetching the API key from configuration.  
  _Default:_ `:brave_ex`

- **`:country`**  
  The country code for the search.  
  _Default:_ `"US"`

- **`:search_lang`**  
  The search language preference.  
  _Default:_ `"en"`

- **`:ui_lang`**  
  The user interface language for the response (e.g., `"en-US"`).  
  _Default:_ `"en-US"`

- **`:count`**  
  The number of search results returned.  
  _Default:_ `20`

- **`:offset`**  
  Pagination offset for search results.  
  _Default:_ `0`

- Other options include `:safesearch`, `:freshness`, `:text_decorations`, `:spellcheck`, `:result_filter`, `:goggles`, `:units`, `:extra_snippets`, and `:summary`.

For full details, please refer to the function documentation inside the module.

## Contributing

Contributions are welcome! If you’d like to help improve BraveEx, feel free to fork the repository and submit pull requests. For any major changes, please open an issue first to discuss what you would like to change.

## License

BraveEx is released under the BSD-3-Clause License.
