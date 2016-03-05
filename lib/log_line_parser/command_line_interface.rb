#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require 'log_line_parser'
require 'log_line_parser/utils'

module LogLineParser
  module CommandLineInterface
    class UnsupportedFormatError < StandardError; end

    DEFAULT_FORMAT = "csv"

    def self.read_configs(config)
      YAML.load_stream(config).to_a
    end

    def self.parse_options
      options = {}

      OptionParser.new("USAGE: #{File.basename($0)} [OPTION]... [LOG_FILE]...") do |opt|
        opt.on("-c [config_file]", "--config [=config_file]",
               "Give a configuration file in yaml format") do |config_file|
          options[:config_file] = config_file
        end

        opt.on("-f", "--filter-mode",
               "Mode for choosing log records that satisfy certain criteria") do
          options[:filter_mode] = true
        end

        opt.on("-l [LogFormat]", "--log_format [=LogFormat]",
               "Specify LogFormat") do |log_format|
          options[:log_format] = log_format
        end

        opt.on("-t [format]", "--to [=format]",
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

    def self.choose_log_parser(log_format)
      return LogLineParser::CombinedLogRecord unless log_format
      parser = LogLineParser::PREDEFINED_FORMATS[log_format]
      parser || LogLineParser.parser(log_format)
    end

    def self.execute_as_converter(options, output=STDOUT, input=ARGF)
      output_format = options[:format] || DEFAULT_FORMAT
      case output_format
      when DEFAULT_FORMAT
        convert_to_csv(input, output)
      when "tsv"
        convert_to_tsv(input, output)
      else
        raise UnsupportedFormatError.new(output_format)
      end
    end

    private

    def self.convert_to_csv(input, output)
      input.each_line do |line|
        output.print Utils.to_csv(line.chomp)
      end
    end

    def self.convert_to_tsv(input, output)
      input.each_line do |line|
        output.puts Utils.to_tsv(line.chomp)
      end
    end
  end
end
