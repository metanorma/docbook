# frozen_string_literal: true

require "nokogiri"

module Docbook
  class XIncludeResolver
    XINCLUDE_NS = "http://www.w3.org/2001/XInclude"

    # Resolve XInclude elements in a Nokogiri document.
    # Handles standard XML includes, text includes, and text+fragid extensions.
    # Processes iteratively to handle nested includes (e.g., file A includes file B
    # which contains text+fragid self-references).
    def self.resolve(doc)
      loop do
        includes = doc.xpath("//xi:include", "xi" => XINCLUDE_NS)
        break if includes.empty?

        resolved_any = false
        includes.each do |inc|
          href = inc["href"]
          next unless href

          parse_mode = inc["parse"] || "xml"
          fragid = inc["fragid"]
          base_dir = base_dir_for(inc.document)
          file_path = resolve_path(base_dir, href)
          next unless file_path && File.exist?(file_path)

          if parse_mode == "text"
            resolve_text_include(doc, inc, file_path, fragid)
          else
            resolve_xml_include(doc, inc, file_path)
          end
          resolved_any = true
          break # re-scan after each resolve (tree changes)
        end
        break unless resolved_any
      end
      doc
    rescue StandardError
      doc
    end

    # Pre-process an XML string to resolve XIncludes before model parsing.
    def self.resolve_string(xml_string, base_path: nil)
      doc = if base_path
              file_uri = "file://#{File.expand_path(base_path)}"
              Nokogiri::XML(xml_string, file_uri)
            else
              Nokogiri::XML(xml_string)
            end
      resolve(doc)
    end

    # ── Include Resolution ──────────────────────────────────────────

    def self.resolve_text_include(doc, inc, file_path, fragid)
      content = File.read(file_path)
      if fragid && !fragid.empty?
        filtered = apply_fragid(content, fragid)
        content = filtered if filtered
      end
      text_node = doc.create_text_node(content)
      inc.replace(text_node)
    end

    def self.resolve_xml_include(doc, inc, file_path)
      included_xml = File.read(file_path)
      included_doc = Nokogiri::XML(included_xml, "file://#{File.expand_path(file_path)}")

      root = included_doc.root
      # Ensure namespace is declared in target document
      if root.namespace
        ns = root.namespace
        existing = doc.root.namespace_definitions.find { |n| n.href == ns.href }
        doc.root.add_namespace_definition(ns.prefix, ns.href) unless existing
      end

      # Replace the xi:include with the root element itself (not its children)
      inc.replace(root.dup)
    end

    def self.base_dir_for(document)
      url = document.url
      return nil unless url

      File.dirname(url.sub(%r{^file://}, ""))
    end

    def self.resolve_path(base_dir, href)
      return nil unless base_dir

      File.join(base_dir, href)
    end

    # ── Fragid Filtering ──────────────────────────────────────────

    # Apply a fragid filter to text content
    def self.apply_fragid(content, fragid)
      if fragid.start_with?("search=")
        apply_search_fragid(content, fragid[7..])
      elsif fragid.start_with?("line=")
        apply_line_fragid(content, fragid[5..])
      elsif fragid.start_with?("char=")
        apply_char_fragid(content, fragid[5..])
      end
    end

    # Apply search= fragid scheme (DocBook xslTNG extension)
    # Syntax: search=#PATTERN#[;after|;before],#STOP#
    #   or:   search=/REGEX/[,/STOP/]
    def self.apply_search_fragid(content, search_spec)
      lines = content.lines
      if search_spec.start_with?("/")
        apply_delimited_search(lines, search_spec, "/")
      elsif search_spec.start_with?("#")
        apply_delimited_search(lines, search_spec, "#")
      end
    end

    # Parse delimited patterns and apply search
    # Delimiter is # (literal) or / (regex)
    def self.apply_delimited_search(lines, spec, delim)
      # Parse: DELIM pattern DELIM [;modifier] [, DELIM stop DELIM]
      remainder = spec[1..] # skip opening delimiter
      close_idx = remainder.index(delim)
      return nil unless close_idx

      pattern_str = remainder[0...close_idx]
      remainder = remainder[(close_idx + 1)..]

      # Check for modifier (;after or ;before)
      modifier = nil
      if remainder&.start_with?(";")
        mod_match = remainder.match(/\A;(after|before)/)
        if mod_match
          modifier = mod_match[1].to_sym
          remainder = remainder[mod_match[0].length..]
        end
      end

      # Skip comma separator
      remainder = remainder[1..] if remainder&.start_with?(",")

      # Parse stop pattern if present
      stop_pattern = nil
      if remainder && !remainder.empty? && remainder.start_with?(delim)
        stop_remainder = remainder[1..]
        stop_close = stop_remainder.index(delim)
        stop_pattern = stop_remainder[0...stop_close] if stop_close
      end

      # Apply search
      match_fn = if delim == "/"
                   ->(line, pat) { line.match?(Regexp.new(pat)) }
                 else
                   ->(line, pat) { line.include?(pat) }
                 end

      start_idx = lines.index { |l| match_fn.call(l, pattern_str) }
      return nil unless start_idx

      # Determine range
      case modifier
      when :after
        range_start = start_idx + 1
      when :before
        range_start = 0
        range_end = start_idx
      else
        range_start = start_idx
      end

      # Find stop (exclusive)
      if stop_pattern
        stop_slice = lines[range_start..]
        stop_idx = stop_slice&.index { |l| match_fn.call(l, stop_pattern) }
        range_end = stop_idx ? range_start + stop_idx : lines.length
      elsif modifier != :before
        range_end = start_idx + 1
      end

      range_end ||= lines.length
      selected = lines[range_start...range_end]
      return nil unless selected && !selected.empty?

      selected.join
    end

    # Apply line= fragid scheme (RFC 5147)
    # Syntax: line=START,END[;length=N]
    def self.apply_line_fragid(content, line_spec)
      parts = line_spec.split(";")
      range_part = parts[0]
      length_part = parts.find { |p| p.start_with?("length=") }

      line_start, line_end = range_part.split(",").map(&:to_i)
      return nil unless line_start && line_end

      lines = content.lines
      selected = lines[(line_start - 1)...(line_end)]
      return nil unless selected

      result = selected.join
      if length_part
        max_len = length_part.split("=")[1].to_i
        result = result[0...max_len] if max_len.positive?
      end
      result
    end

    # Apply char= fragid scheme (RFC 5147)
    # Syntax: char=START,END
    def self.apply_char_fragid(content, char_spec)
      char_start, char_end = char_spec.split(",").map(&:to_i)
      return nil unless char_start && char_end

      content[char_start...char_end]
    end
  end
end
