#!/usr/bin/env ruby

require 'log_line_parser'
require 'csv'
require 'yaml'

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

    def self.open_multiple_output_files(base_names, dir=nil, ext="log")
      logs = {}
      filepath = dir ? File.join(dir, "%s.#{ext}") : "%s.#{ext}"
      base_names.each do |base|
        logs[base] = open(format(filepath, base), "w")
      end
      yield logs
    ensure
      logs.each_value {|v| v.close }
    end

    def self.read_configs(config)
      YAML.load_stream(config).to_a
    end

    def self.load_config_file(config_file)
      open(File.expand_path(config_file)) do |f|
        read_configs(f.read)
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

    # private class methods

    def self.escape_special_chars(field)
      field.gsub(SPECIAL_CHARS_RE) do |char|
        SPECIAL_CHARS[char]
      end
    end

    private_class_method :escape_special_chars
  end
end
