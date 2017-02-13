#!/usr/bin/env ruby

require 'minitest_helper'
require 'log_line_parser/command_line_interface'
require 'shellwords'
require 'stringio'
require 'fileutils'

def setup_argv(command_lin_str)
  ARGV.replace Shellwords.split(command_lin_str)
end

class TestLogLineParser < Minitest::Test
  include LogLineParser

  def test_load
    yaml_data = <<YAML_DATA
---
host_name: www.example.org
resources:
 - /start.html
 - /subdir/index.html
queries:
 - :access_to_resources?
 - :referred_from_resources?
output_log_name: start_or_subidir-index
---
host_name: www.example.net
resources:
 - /index.html
queries:
 - :access_to_under_resources?
YAML_DATA

expected_result = [
      { "host_name" => "www.example.org",
        "resources" => ["/start.html",
          "/subdir/index.html"],
        "queries" => [:access_to_resources?, :referred_from_resources?],
        "output_log_name" => "start_or_subidir-index" },
      { "host_name" => "www.example.net",
        "resources" => ["/index.html"],
        "queries" => [:access_to_under_resources?] }
    ]

    parsed_result = Utils.read_configs(yaml_data)
    assert_equal(expected_result, parsed_result)
  end

  def test_parse_options
    setup_argv("--config=config.yaml")
    opts = CommandLineInterface.parse_options
    expected_result =  { log_format: LogLineParser::CombinedLogParser, config_file: "config.yaml" }
    assert_equal(expected_result, opts)

    setup_argv("--to=csv")
    opts = CommandLineInterface.parse_options
    expected_result =  { log_format: LogLineParser::CombinedLogParser, format: "csv" }
    assert_equal(expected_result, opts)
  end

  def test_choose_log_parser
    setup_argv("--log-format=common")
    opts = CommandLineInterface.parse_options
    assert_equal(CommonLogParser, opts[:log_format])

    setup_argv("--to=csv")
    opts = CommandLineInterface.parse_options
    assert_equal(CombinedLogParser, opts[:log_format])

    setup_argv("--log-format=common_with_vh")
    opts = CommandLineInterface.parse_options
    assert_equal(CommonLogWithVHParser, opts[:log_format])
  end

  def test_execute_as_converter_to_csv
    setup_argv("--to=csv")
    opts = CommandLineInterface.parse_options
    output = StringIO.new(String.new, "w")
    expected_csv = File.read("test/data/expected_combined_log.csv")
    CommandLineInterface.execute_as_converter(opts,
                                              output,
                                              open("test/data/example_combined_log.log"))
    assert_equal(expected_csv, output.string)
  end

  def test_execute_as_converter_to_tsv
    setup_argv("--to=tsv")
    opts = CommandLineInterface.parse_options
    output = StringIO.new(String.new, "w")
    expected_tsv = File.read("test/data/expected_combined_log.tsv")
    CommandLineInterface.execute_as_converter(opts,
                                              output,
                                              open("test/data/example_combined_log.log"))
    assert_equal(expected_tsv, output.string)
  end

  def test_execute_as_converter_to_ltsv
    setup_argv("--to=ltsv")
    opts = CommandLineInterface.parse_options
    output = StringIO.new(String.new, "w")
    expected_tsv = File.read("test/data/expected_combined_log.ltsv")
    CommandLineInterface.execute_as_converter(opts,
                                              output,
                                              open("test/data/example_combined_log.log"))
    assert_equal(expected_tsv, output.string)
  end

  def test_execute_as_filter
    tmp_dir = "test/data/tmp"
    result_log_names = %w(start_or_subidir-index.log to_and_from_index.log)
    delete_files(result_log_names, tmp_dir)
    expected_outputs = read_files(result_log_names, "test/data/filter_mode_results")
    setup_argv("--filter-mode -o #{tmp_dir} -c test/data/example_config.yaml test/data/example_combined_log.log")
    opts = CommandLineInterface.parse_options
    CommandLineInterface.execute_as_filter(opts)
    results = read_files(result_log_names, tmp_dir)
    assert_equal(expected_outputs, results)
  ensure
    delete_files(result_log_names, tmp_dir)
  end

  def test_execute_as_filter_with_error_log
    tmp_dir = "test/data/tmp"
    result_log_names = %w(start_or_subidir-index.log to_and_from_index.log error.log)
    error_log_path = File.join(tmp_dir, result_log_names[2])
    input_logs = %w(example_combined example_malformed).map {|log| "test/data/#{log}_log.log" }.join(" ")
    delete_files(result_log_names, tmp_dir)
    expected_output = "192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] \"GET /index.html HTTP/1.1\" 200 432\n"
    setup_argv("--filter-mode -o #{tmp_dir} -c test/data/example_config.yaml -e #{error_log_path} #{input_logs}")
    opts = CommandLineInterface.parse_options
    CommandLineInterface.execute_as_filter(opts)
    result = File.read(error_log_path)
    assert_equal(expected_output, result)
  ensure
    delete_files(result_log_names, tmp_dir)
  end

  private

  def read_files(filenames, path)
    filenames.map do |file|
      File.read(File.join(path, file))
    end
  end

  def delete_files(names, path)
    names.each do |name|
      file = File.join(path, name)
      FileUtils.rm(file) if File.exist? file
    end
  end
end
