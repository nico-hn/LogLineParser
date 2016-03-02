#!/usr/bin/env ruby

require 'yaml'
require 'optparse'

module LogLineParser
  module CommandLineInterFace
    def self.read_configs(config)
      YAML.load_stream(config).to_a
    end

    def self.parse_options
      options = {}

      OptionParser.new("USAGE: #{File.basename($0)} [OPTION]... [LOG_FILE]...") do |opt|
        opt.on("-f [config_file]", "--filter [=config_file]",
               "Give a configuration file in yaml format") do |config_file|
          options[:config_file] = config_file
        end

        opt.on("-c [format]", "--convert [=format]",
               "Specify a format") do |format|
          options[:format] = format
        end

        opt.parse!
      end

      options
    end

    def self.load_config_file(config_file)
      open(File.expand_path(config_file)) do |f|
        read_configs(f.read)
      end
    end
  end
end
