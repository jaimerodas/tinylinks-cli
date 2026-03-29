# frozen_string_literal: true

module Tinylinks
  class Formatter
    def initialize(color: false)
      @c = Colorizer.new(enabled: color)
    end

    def link(data)
      lines = []
      lines << @c.bold("#{data["title"] || "(untitled)"} [##{data["id"]}]")
      lines << "  #{@c.cyan(data["url"])}"
      lines << "  #{@c.dim(data["description"])}" if data["description"] && !data["description"].empty?
      lines << "  tags: #{@c.green(data["tags"].join(", "))}" if data["tags"] && !data["tags"].empty?
      lines.join("\n")
    end

    def link_list(data)
      return @c.dim("No results found") if data["links"].empty?

      lines = data["links"].map { |l| link(l) }
      lines << @c.dim(pagination(data["meta"])) if data["meta"]
      lines.join("\n\n")
    end

    def tags(data)
      return @c.dim("No results found") if data["tags"].empty?

      data["tags"].map { |t| "#{@c.green(t["name"])} #{@c.dim("(#{t["count"]})")}" }.join("\n")
    end

    def errors(data)
      data["errors"].flat_map do |field, messages|
        messages.map { |msg| @c.red("#{field} #{msg}") }
      end.join("\n")
    end

    private

    def pagination(meta)
      "Page #{meta["page"]} of #{meta["total_pages"]} (#{meta["total_items"]} total)"
    end
  end
end
