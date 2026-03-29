# frozen_string_literal: true

require "thor"

module Tinylinks
  class CLI < Thor
    def self.exit_on_failure?
      true
    end

    class_option :help, aliases: "-h", type: :boolean, desc: "Show help for a command"

    no_commands do
      def invoke_command(command, *args)
        if options[:help]
          CLI.command_help(shell, command.name)
          return
        end
        super
      rescue Client::ApiError => e
        if e.body.is_a?(Hash) && e.body["errors"]
          say_error formatter.errors(e.body)
        else
          say_error e.message
        end
        exit 1
      end
    end

    desc "login", "Authenticate with TinyLinks"
    def login
      auth = Auth.new
      if auth.logged_in?
        say "Already logged in."
        return
      end

      say "Starting device authorization..."
      auth.login do |event, url|
        if event == :open_browser
          say "Opening browser for authorization..."
          say "If it doesn't open, visit: #{url}"
          system("open", url)
        end
      end
      say "Login successful!"
    rescue RuntimeError => e
      say_error "Login failed: #{e.message}"
      exit 1
    end

    desc "logout", "Remove stored credentials"
    def logout
      Auth.new.logout
      say "Logged out."
    end

    desc "list", "List links"
    method_option :tags, type: :string, desc: "Filter by tags (comma-separated)"
    method_option :page, type: :numeric, desc: "Page number"
    def list
      params = {}
      params[:tags] = options[:tags] if options[:tags]
      params[:page] = options[:page] if options[:page]
      data = client.get("/links", params)
      say formatter.link_list(data)
    end

    desc "show ID", "Show a link"
    def show(id)
      data = client.get("/links/#{id}")
      say formatter.link(data["link"])
    end

    desc "add URL", "Add a new link"
    method_option :title, type: :string, desc: "Link title"
    method_option :description, type: :string, desc: "Link description"
    method_option :tags, type: :string, desc: "Tags (comma-separated)"
    def add(url)
      body = {url: url}
      body[:title] = options[:title] if options[:title]
      body[:description] = options[:description] if options[:description]
      body[:tags] = options[:tags].split(",").map(&:strip) if options[:tags]
      data = client.post("/links", body)
      say formatter.link(data["link"])
    end

    desc "edit ID", "Edit a link"
    method_option :title, type: :string, desc: "Link title"
    method_option :description, type: :string, desc: "Link description"
    method_option :tags, type: :string, desc: "Tags (comma-separated)"
    def edit(id)
      body = {}
      body[:title] = options[:title] if options[:title]
      body[:description] = options[:description] if options[:description]
      body[:tags] = options[:tags].split(",").map(&:strip) if options[:tags]

      if body.empty?
        say_error "No changes specified. Use --title, --description, or --tags."
        exit 1
      end

      data = client.patch("/links/#{id}", body)
      say formatter.link(data["link"])
    end

    desc "search QUERY", "Search links"
    method_option :page, type: :numeric, desc: "Page number"
    def search(query)
      params = {q: query}
      params[:page] = options[:page] if options[:page]
      data = client.get("/search", params)
      say formatter.link_list(data)
    end

    desc "tags", "List all tags"
    method_option :sort, type: :string, desc: "Sort order: name (default) or popularity"
    def tags
      params = {}
      params[:sort_by] = options[:sort] if options[:sort]
      data = client.get("/tags", params)
      say formatter.tags(data)
    end

    desc "untagged", "List links without tags"
    method_option :page, type: :numeric, desc: "Page number"
    def untagged
      params = {}
      params[:page] = options[:page] if options[:page]
      data = client.get("/untagged", params)
      say formatter.link_list(data)
    end

    desc "version", "Show version"
    def version
      say "tinylinks #{VERSION}"
    end

    private

    def client
      @client ||= begin
        token = Auth.new.token
        unless token
          say_error "Not logged in. Run `tinylinks login` first."
          exit 1
        end
        Client.new(token: token)
      end
    end

    def formatter
      @formatter ||= Formatter.new
    end

    def say_error(message)
      $stderr.puts message
    end
  end
end
