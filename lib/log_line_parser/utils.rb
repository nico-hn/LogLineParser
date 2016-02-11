#!/usr/bin/env ruby

module LogLineParser
  module Utils
    def open_multiple_output_files(base_names, dir=nil, ext="log")
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
