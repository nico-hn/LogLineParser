#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require 'log_line_parser'
require 'log_line_parser/query'
require 'log_line_parser/utils'

module LogLineParser
  module CommandLineInterface
    class UnsupportedFormatError < StandardError; end

    class Converter
      def execute(options, output=STDOUT, input=ARGF)
        output_format = options[:format] || DEFAULT_FORMAT
        case output_format
        when DEFAULT_FORMAT
          to_csv(input, output)
        when "tsv"
          to_tsv(input, output)
        when "ltsv"
          to_ltsv(input, output, options[:log_format])
        else
          raise UnsupportedFormatError.new(output_format)
        end
      end

      def to_csv(input, output)
        input.each_line do |line|
          output.print Utils.to_csv(line.chomp)
        end
      end

      def to_tsv(input, output)
        input.each_line do |line|
          output.puts Utils.to_tsv(line.chomp)
        end
      end

      def to_ltsv(input, output, parser)
        input.each_line do |line|
          output.puts parser.to_ltsv(line.chomp)
        end
      end
    end

    class Filter
      OptionValues = Struct.new(:configs, :bots_re, :output_log_names,
                                :output_dir, :log_format, :error_log)

      def execute(options)
        opt = option_values(options)
        Utils.open_multiple_output_files(opt.output_log_names,
                                         opt.output_dir) do |logs|
          queries = setup_queries_from_configs(opt.configs, logs, opt.bots_re)
          LogLineParser.each_record(error_output: opt.error_log || STDERR,
                                    parser: opt.log_format) do |line, record|
            queries.each {|query| query.call(line, record) }
          end
        end
      ensure
        opt.error_log.close if opt.error_log
      end

      private

      def option_values(options)
        configs = Utils.load_config_file(options[:config_file])
        bots_re = Utils.compile_bots_re_from_config_file(options[:bots_config_file])
        error_log = open_error_log(options[:error_log_file])
        OptionValues.new(configs,
                         bots_re,
                         collect_output_log_names(configs),
                         options[:output_dir],
                         options[:log_format],
                         error_log)
      end

      def collect_output_log_names(configs)
        configs.map do |config|
          config[Query::ConfigFields::OUTPUT_LOG_NAME]
        end
      end

      def setup_queries_from_configs(configs, logs, bots_re)
        configs.map do |config|
          Query.register_query_to_log(config, logs, bots_re)
        end
      end

      def open_error_log(log_file)
        open(File.expand_path(log_file), "wb") if log_file
      end
    end

    DEFAULT_FORMAT = "csv"

    def self.parse_options
      options = { log_format: LogLineParser::CombinedLogParser }

      OptionParser.new("USAGE: #{File.basename($0)} [OPTION]... [LOG_FILE]...") do |opt|
        opt.on("-c [config_file]", "--config [=config_file]",
               "Give a configuration file in yaml format") do |config_file|
          options[:config_file] = config_file
        end

        opt.on("-b [bots_config_file]", "--bots-config [=bots_config_file]",
               "Give a configuration file in yaml format. \
Default bots: #{Bots::DEFAULT_BOTS.join(', ')}") do |config_file|
          options[:bots_config_file] = config_file
        end

        opt.on("-s", "--show-current-settings",
               "Show the detail of the current settings") do
          options[:show_settings] = true
        end

        opt.on("-f", "--filter-mode",
               "Mode for choosing log records that satisfy certain criteria") do
          options[:filter_mode] = true
        end

        opt.on("-l [LogFormat]", "--log-format [=LogFormat]",
               "Specify LogFormat by giving a LogFormat or one of \
formats predefined as #{predefined_options_for_log_format}") do |log_format|
          options[:log_format] = choose_log_parser(log_format)
        end

        opt.on("-o [output_dir]", "--output-dir [=output_dir]",
               "Specify the output directory for log files") do |output_dir|
          options[:output_dir] = output_dir
        end

        opt.on("-t [format]", "--to [=format]",
               "Specify a format: csv, tsv or ltsv") do |format|
          options[:format] = format
        end

        opt.on("-e [error_log_file]", "--error-log [=error_log_file]",
               "Specify a file for error logging") do |error_log_file|
          options[:error_log_file] = error_log_file
        end

        opt.parse!
      end

      options
    end

    def self.choose_log_parser(log_format)
      parser = LogLineParser::PREDEFINED_FORMATS[log_format]
      parser || LogLineParser.parser(log_format)
    end

    def self.execute
      options = parse_options
      if options[:show_settings]
        show_settings(options)
      elsif options[:filter_mode]
        execute_as_filter(options)
      else
        execute_as_converter(options)
      end
    end

    def self.show_settings(options)
      bots_re = Utils.compile_bots_re_from_config_file(options[:bots_config_file])
      parser = options[:log_format]
      puts "The regular expression for bots: #{bots_re}"
      puts "LogFormat: #{parser.format_strings}"
    end

    def self.execute_as_filter(options)
      Filter.new.execute(options)
    end

    def self.execute_as_converter(options, output=STDOUT, input=ARGF)
      Converter.new.execute(options, output, input)
    end

    # private class methods

    def self.predefined_options_for_log_format
      PREDEFINED_FORMATS.keys.
        map {|opt| "\"#{opt}\"" }.
        join(", ")
    end

    private_class_method :predefined_options_for_log_format
  end
end
