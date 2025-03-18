---
title: Documentation Guide
---

# Documentation Guide

This guide explains how to document code and automatically generate a documentation site.

## YARD Documentation

Wikidotrb uses [YARD](https://yardoc.org/) for documentation generation from code comments. YARD provides a simple syntax for documenting Ruby code, which is then rendered into beautiful documentation.

### Basic Syntax

YARD comments start with `#` and documentation tags start with `@`:

```ruby
# This is a regular comment
#
# @param [String] name The name of the person
# @param [Integer] age The age of the person
# @return [Boolean] Whether the person is an adult
def is_adult?(name, age)
  puts "Checking if #{name} is an adult..."
  age >= 18
end
```

### Important Tags

Here are some important YARD tags you should use:

| Tag | Description | Example |
|-----|-------------|---------|
| `@param` | Documents a method parameter | `@param [Array<String>] names A list of names` |
| `@return` | Documents what a method returns | `@return [Boolean] Whether the operation was successful` |
| `@example` | Provides an example of using the method | `@example Getting a page\n  client.get_page(page_name: "start")` |
| `@see` | Provides a reference to another object or URL | `@see Client#get_page` |
| `@note` | Adds a note about special considerations | `@note This method is not thread-safe` |
| `@todo` | Indicates future improvements | `@todo Implement caching` |
| `@deprecated` | Marks a method as deprecated | `@deprecated Use {#new_method} instead` |

### Documenting Classes and Modules

```ruby
# The Client class provides methods for interacting with Wikidot sites.
#
# @example Creating a new client
#   client = Wikidotrb::Module::Client.new(site_name: "example")
#
# @example Authenticating the client
#   client.authenticate(username: "user", password: "pass")
#
# @attr [String] site_name The name of the site to connect to
# @attr_reader [Boolean] logged_in Whether the client is logged in
class Client
  # ...
end
```

### Documenting Methods

```ruby
# Gets the content of a page.
#
# @param [String] page_name The name of the page to retrieve
# @param [Boolean] include_metadata Whether to include metadata in the response
# @return [Page] The page object with content and metadata
# @raise [PageNotFoundError] If the page does not exist
# @see Page
# @example
#   page = client.get_page(page_name: "start")
#   puts page.content
def get_page(page_name:, include_metadata: true)
  # ...
end
```

## RBS Type Definitions

In addition to YARD documentation, Wikidotrb uses [RBS](https://github.com/ruby/rbs) for type definitions. These type definitions are also included in the generated documentation.

### Basic Syntax

```ruby
# In sig/wikidotrb.rbs
module Wikidotrb
  module Module
    class Client
      attr_reader site_name: String
      attr_reader logged_in: bool
      
      def initialize: (site_name: String) -> void
      def authenticate: (username: String, password: String) -> bool
      def get_page: (page_name: String, ?include_metadata: bool) -> Page
    end
    
    class Page
      attr_reader title: String
      attr_reader content: String
      attr_reader metadata: Hash[Symbol, untyped]
      
      def initialize: (title: String, content: String, ?metadata: Hash[Symbol, untyped]) -> void
    end
  end
end
```

## Best Practices

1. **Document Everything**: Every class, module, method, and attribute should be documented.
2. **Be Concise**: Keep your documentation clear and to the point.
3. **Provide Examples**: Examples help users understand how to use your code.
4. **Use Type Annotations**: Always specify types for parameters and return values.
5. **Keep RBS Updated**: When changing code, make sure to update the corresponding RBS type definitions.
6. **Test Documentation**: Ensure that your documentation generates correctly by running `make docs` and checking the output.

## Generating Documentation

To generate the documentation, run:

```bash
make docs
```

This will:
1. Generate YARD documentation
2. Generate RDoc documentation
3. Process RBS files
4. Build the Jekyll site

To view the documentation locally, run:

```bash
make docs-serve
```

Then visit [http://localhost:4000](http://localhost:4000) in your browser.
