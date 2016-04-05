#!/usr/bin/env ruby

require 'yaml'
require 'optparse'
require 'log_line_parser'
require 'log_line_parser/query'
require 'log_line_parser/utils'

module LogLineParser
  module CommandLineInterface
    class UnsupportedFormatError < StandardError; end

    DEFAULT_FORMAT = "csv"

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

        opt.on("-l [LogFormat]", "--log-format [=LogFormat]",
               "Specify LogFormat by giving a LogFormat or one of \
formats predefined as #{predefined_options_for_log_format}") do |log_format|
          options[:log_format] = log_format
        end

        opt.on("-o [output_dir]", "--output-dir [=output_dir]",
               "Specify the output directory for log files") do |output_dir|
          options[:output_dir] = output_dir
        end

        opt.on("-t [format]", "--to [=format]",
               "Specify a format: csv, tsv or ltsv") do |format|
          options[:format] = format
        end

        opt.parse!
      end

      options
    end

    def self.choose_log_parser(log_format)
      return LogLineParser::CombinedLogParser unless log_format
      parser = LogLineParser::PREDEFINED_FORMATS[log_format]
      parser || LogLineParser.parser(log_format)
    end

    def self.execute
      options = parse_options
      if options[:filter_mode]
        execute_as_filter(options)
      else
        execute_as_converter(options)
      end
    end

    def self.execute_as_filter(options)
      configs = Utils.load_config_file(options[:config_file])
      parser = choose_log_parser(options[:log_format])
      output_dir = options[:output_dir]
      execute_queries(configs, parser, output_dir)
    end

    def self.execute_as_converter(options, output=STDOUT, input=ARGF)
      output_format = options[:format] || DEFAULT_FORMAT
      case output_format
      when DEFAULT_FORMAT
        convert_to_csv(input, output)
      when "tsv"
        convert_to_tsv(input, output)
      when "ltsv"
        convert_to_ltsv(input, output,
                        choose_log_parser(options[:log_format]))
      else
        raise UnsupportedFormatError.new(output_format)
      end
    end

    private

    def self.predefined_options_for_log_format
      PREDEFINED_FORMATS.keys.
        map {|opt| "\"#{opt}\"" }.
        join(", ")
    end

    def self.compile_bots_re_from_config_file(bots_config_file)
      return Bots::DEFAULT_RE unless bots_config_file
      configs = Utils.load_config_file(bots_config_file)[0]
      Bots.compile_bots_re(configs)
    end

    def self.collect_output_log_names(configs)
      configs.map do |config|
        config[Query::ConfigFields::OUTPUT_LOG_NAME]
      end
    end

    def self.execute_queries(configs, parser, output_dir)
      output_log_names = collect_output_log_names(configs)
      Utils.open_multiple_output_files(output_log_names, output_dir) do |logs|
        queries = setup_queries_from_configs(configs, logs, Bots::DEFAULT_RE)
        LogLineParser.each_record(parser: parser) do |line, record|
          queries.each {|query| query.call(line, record) }
        end
      end
    end

    def self.setup_queries_from_configs(configs, logs, bots_re)
      configs.map do |config|
        Query.register_query_to_log(config, logs, bots_re)
      end
    end

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

    def self.convert_to_ltsv(input, output, parser)
      input.each_line do |line|
        output.puts parser.to_ltsv(line.chomp)
      end
    end
  end
end
