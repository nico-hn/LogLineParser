#!/usr/bin/env ruby

require 'log_line_parser'
require 'log_line_parser/query'
require 'csv'

module LogLineParser
  module Utils
    TAB = "\t"
    SPECIAL_CHARS = {
      "\t" => '\\t',
      "\n" => '\\n',
      "\r" => '\\r',
      '\\\\' => '\\\\',
    }
    SPECIAL_CHARS_RE = Regexp.compile(SPECIAL_CHARS.keys.join("|"))

    def self.access_by_bots?(record, bots_re=Query::DEFAULT_BOTS_RE)
      Query.access_by_bots?(record, bots_re)
    end

    def self.open_multiple_output_files(base_names, dir=nil, ext="log")
      logs = {}
      filepath = dir ? File.join(dir, "%s.#{ext}") : "%s.#{ext}"
      base_names.each do |base|
        logs[base] = open(format(filepath, base), "w")
      end
      yield logs
    ensure
      logs.each do |k, v|
        v.close
      end
    end

    def self.to_tsv(line, escape=true)
      LogLineParser.parse(line).to_a.map do |field|
        escape ? escape_special_chars(field) : field
      end.join(TAB)
    end

    def self.to_csv(line)
      LogLineParser.parse(line).to_a.to_csv
    end

    private

    def self.escape_special_chars(field)
      field.gsub(SPECIAL_CHARS_RE) do |char|
        SPECIAL_CHARS[char]
      end
    end
  end
end
