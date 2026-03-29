# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Ruby CLI gem for the TinyLinks bookmarking API (`https://links.pati.to/api/v1/`). Uses Thor for subcommands, Net::HTTP for API calls, OAuth 2.0 Device Authorization Grant for auth.

## Commands

- **Run full tests:** `./script/test` or `bundle exec rake test`
- **Run a single test file:** `bundle exec ruby -Ilib -Itest test/tinylinks/client_test.rb`
- **Run a single test method:** `bundle exec ruby -Ilib -Itest test/tinylinks/client_test.rb -n test_get_returns_parsed_json`
- **Install deps:** `bundle install`
- **Try the CLI:** `bundle exec tinylinks <command>`

Ruby 4.0.2 managed via mise (`mise.toml`).

## Architecture

- `lib/tinylinks.rb` — top-level module, version, requires
- `lib/tinylinks/client.rb` — HTTP client (Net::HTTP wrapper). GET/POST/PATCH with JSON + Bearer auth. Raises `Client::ApiError` on non-2xx responses.
- `lib/tinylinks/auth.rb` — Device flow OAuth (request code → browser → poll). Stores token in `~/.config/tinylinks/credentials.json`.
- `lib/tinylinks/formatter.rb` — Terminal output: link display, lists with pagination, tags, error messages.
- `lib/tinylinks/cli.rb` — Thor CLI. `invoke_command` override catches `ApiError` for clean error output.

## Testing

- Minitest + WebMock. All HTTP is stubbed — no real API calls in tests.
- `test/test_helper.rb` has `TestFixtures` module with `sample_link`, `sample_meta`, and `stub_api` helpers.
- CLI tests use in-process Thor invocation via `capture_cli` (captures `$stdout`).
- Auth tests swap `CREDENTIALS_DIR`/`CREDENTIALS_FILE` constants to a tmpdir.

## API Reference

Full docs at `~/Developer/tinylinks/docs/api.md`. Base URL: `https://links.pati.to/api/v1/`.
