# Wikidotrb Documentation

This directory contains the documentation for the Wikidotrb library, built with Jekyll and Just the Docs.

## Directory Structure

- `_config.yml` - Jekyll configuration
- `_layouts/` - HTML layouts
- `_includes/` - Reusable components
- `_scripts/` - Ruby scripts for processing documentation
- `api/` - API reference documentation
- `assets/` - CSS, JavaScript, and images
- `*.md` - Markdown content pages

## Building Documentation

From the project root:

```bash
# Install dependencies and build docs
make docs

# Serve docs locally
make docs-serve
```

## Documentation Process

1. YARD extracts documentation from Ruby code comments
2. RDoc generates additional API documentation
3. RBS type definitions are processed
4. Jekyll builds the static site with the processed documentation

## Adding Content

To add new content:

1. Create a new Markdown file in the appropriate directory
2. Add front matter with layout, title, and navigation order
3. Add your content in Markdown format

Example:

```markdown
---
layout: default
title: My New Page
nav_order: 5
---

# My New Page

Content goes here...
```

## Documenting Code

See [Documentation Guide](documentation-guide.md) for details on how to document your Ruby code.
