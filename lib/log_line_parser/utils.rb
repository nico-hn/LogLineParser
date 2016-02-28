#!/usr/bin/env ruby

require 'log_line_parser/query'

module LogLineParser
  module Utils
    def self.access_by_bots?(record, bots_re=Query::DEFAULT_BOTS_RE)
      Query.access_by_bots?(record, bots_re)
    end

    def self.referred_from?(record, resources=[])
      resources.include?(record.referer_resource)
    end

    def self.referred_from_under?(record, path)
        record.referer_resource.start_with?(path)
    end

    def self.access_to_resources?(record, resources=[])
      resources.include?(record.resource)
    end

    def self.access_to_resources_under?(record, path)
      record.resource.start_with?(path)
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
  end
end
