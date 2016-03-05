#!/usr/bin/env ruby

require 'minitest_helper'
require 'log_line_parser/command_line_interface'
require 'shellwords'
require 'stringio'

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

    parsed_result = CommandLineInterFace.read_configs(yaml_data)
    assert_equal(expected_result, parsed_result)
  end

  def test_parse_options
    setup_argv("--config=config.yaml")
    opts = CommandLineInterFace.parse_options
    expected_result =  { :config_file => "config.yaml" }
    assert_equal(expected_result, opts)

    setup_argv("--to=csv")
    opts = CommandLineInterFace.parse_options
    expected_result =  { :format => "csv" }
    assert_equal(expected_result, opts)
  end

  def test_choose_log_format
    setup_argv("--log_format=common")
    opts = CommandLineInterFace.parse_options
    log_format = CommandLineInterFace.choose_log_format(opts)
    assert_equal(CommonLogRecord, log_format)

    setup_argv("--to=csv")
    opts = CommandLineInterFace.parse_options
    log_format = CommandLineInterFace.choose_log_format(opts)
    assert_equal(CombinedLogRecord, log_format)

    setup_argv("--log_format=common_with_vh")
    opts = CommandLineInterFace.parse_options
    log_format = CommandLineInterFace.choose_log_format(opts)
    assert_equal(CommonLogWithVHRecord, log_format)
  end

  def test_execute_as_converter_to_csv
    setup_argv("--to=csv")
    opts = CommandLineInterFace.parse_options
    output = StringIO.new(String.new, "w")
    expected_csv = File.read("test/data/expected_combined_log.csv")
    CommandLineInterFace.execute_as_converter(opts,
                                              output,
                                              open("test/data/example_combined_log.log"))
    assert_equal(expected_csv, output.string)
  end
end
