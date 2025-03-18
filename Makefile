.PHONY: docs docs-server docs-static install-docs-deps generate-llms-txt gh-pages

# Default target
all: docs

# Install dependencies for documentation
install-docs-deps:
	cd wikidotrb && \
	bundle config set --local with 'development documentation'; \
	bundle install

# Generate documentation
docs: install-docs-deps clean-docs
	cd wikidotrb && \
	bundle exec yard doc -o docs/api/yard --no-save --no-stats && \
	mkdir -p docs/api && \
	bundle exec ruby docs/_scripts/process_yard_docs.rb && \
	bundle exec ruby docs/_scripts/generate_llms_txt.rb

# Generate llms.txt files compliant with llmstxt.org standard
generate-llms-txt:
	cd wikidotrb && \
	bundle exec yard doc --no-save --no-stats && \
	bundle exec ruby docs/_scripts/generate_llms_txt.rb

# Serve documentation using Ruby's built-in HTTP server
docs-server: docs
	@echo "Starting HTTP server on http://localhost:4001"
	@echo "Press Ctrl+C to stop"
	cd wikidotrb && \
	ruby -run -e httpd docs/api/yard -p 4001

# Prepare for GitHub Pages deployment
gh-pages: docs
	@echo "Documentation ready for GitHub Pages deployment"
	@echo "To deploy, push the docs/ directory to the gh-pages branch"
	@echo "Example:"
	@echo "  git checkout -b gh-pages"
	@echo "  git add -f wikidotrb/docs/_site/"
	@echo "  git commit -m 'Update documentation'"
	@echo "  git push origin gh-pages"

# Clean documentation artifacts
clean-docs:
	rm -rf wikidotrb/docs/_site
	rm -rf wikidotrb/docs/api/yard
	rm -rf wikidotrb/docs/api/rdoc
	rm -rf wikidotrb/docs/api/rbs
	rm -f wikidotrb/llms.txt
	rm -f wikidotrb/llms-full.txt
	rm -f wikidotrb/docs/_site/llms.txt
	rm -f wikidotrb/docs/_site/llms-full.txt
	[ -d wikidotrb/docs/api/rdoc ] && rm -rf wikidotrb/docs/api/rdoc || true

clean: clean-docs
