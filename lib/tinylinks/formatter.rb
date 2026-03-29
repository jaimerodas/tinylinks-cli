# frozen_string_literal: true

module Tinylinks
  class Formatter
    def link(data)
      lines = []
      lines << "#{data["title"] || "(untitled)"} [##{data["id"]}]"
      lines << "  #{data["url"]}"
      lines << "  #{data["description"]}" if data["description"] && !data["description"].empty?
      lines << "  tags: #{data["tags"].join(", ")}" if data["tags"] && !data["tags"].empty?
      lines.join("\n")
    end

    def link_list(data)
      lines = data["links"].map { |l| link(l) }
      lines << pagination(data["meta"]) if data["meta"]
      lines.join("\n\n")
    end

    def tags(data)
      data["tags"].map { |t| "#{t["name"]} (#{t["count"]})" }.join("\n")
    end

    def errors(data)
      data["errors"].flat_map do |field, messages|
        messages.map { |msg| "#{field} #{msg}" }
      end.join("\n")
    end

    private

    def pagination(meta)
      "Page #{meta["page"]} of #{meta["total_pages"]} (#{meta["total_items"]} total)"
    end
  end
end
