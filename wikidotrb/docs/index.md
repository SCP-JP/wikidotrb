---
layout: default
title: Home
nav_order: 1
permalink: /
---

# Wikidotrb Documentation

Welcome to the documentation for **Wikidotrb**, a Ruby client library for interacting with Wikidot sites.

## Getting Started

Wikidotrb makes it simple to interact with Wikidot sites programmatically. Here's a quick example:

```ruby
require 'wikidotrb'

# Create a client
client = Wikidotrb::Module::Client.new(site_name: "example")

# Get information about a page
page = client.get_page(page_name: "start")
puts page.title

# Authenticate (if needed)
client.authenticate(username: "user", password: "pass")

# Edit a page
client.edit_page(
  page_name: "start",
  title: "New Title",
  content: "Hello, world!"
)
```

## API Documentation

The API documentation is organized into the following sections:

- [API Reference](api) - Complete reference of all classes and modules
- [RBS Type Definitions](api/rbs) - Type definitions for the library
- [Source Documentation](api/yard) - Generated documentation from source comments

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'wikidotrb'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install wikidotrb
```

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](https://github.com/username/wikidotrb/blob/main/CONTRIBUTING.md) for details.

## License

This project is licensed under the terms of the MIT license. See [LICENSE](https://github.com/username/wikidotrb/blob/main/LICENSE) for more information.
