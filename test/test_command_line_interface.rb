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

    parsed_result = Utils.read_configs(yaml_data)
    assert_equal(expected_result, parsed_result)
  end

  def test_parse_options
    setup_argv("--config=config.yaml")
    opts = CommandLineInterface.parse_options
    expected_result =  { :config_file => "config.yaml" }
    assert_equal(expected_result, opts)

    setup_argv("--to=csv")
    opts = CommandLineInterface.parse_options
    expected_result =  { :format => "csv" }
    assert_equal(expected_result, opts)
  end

  def test_choose_log_parser
    setup_argv("--log-format=common")
    opts = CommandLineInterface.parse_options
    parser = CommandLineInterface.choose_log_parser(opts[:log_format])
    assert_equal(CommonLogParser, parser)

    setup_argv("--to=csv")
    opts = CommandLineInterface.parse_options
    parser = CommandLineInterface.choose_log_parser(opts[:log_format])
    assert_equal(CombinedLogParser, parser)

    setup_argv("--log-format=common_with_vh")
    opts = CommandLineInterface.parse_options
    parser = CommandLineInterface.choose_log_parser(opts[:log_format])
    assert_equal(CommonLogWithVHParser, parser)
  end

  def test_compile_bots_re_from_config_file
    bots_re = CommandLineInterface.compile_bots_re_from_config_file("test/data/example_bots.yaml")
    default_bots_re = CommandLineInterface.compile_bots_re_from_config_file(nil)
    bots_only_re = CommandLineInterface.compile_bots_re_from_config_file("test/data/example_bots_re.yaml")
    expected_bots_re = /(?i-mx:Googlebot|Googlebot\-Mobile|Mediapartners\-Google|Bingbot|Slurp|Baiduspider|BaiduImagespider|BaiduMobaider|YetiBot|Applebot)|(?-mix: bot$)/
    expected_default_bots_re = /Googlebot|Googlebot\-Mobile|Mediapartners\-Google|Bingbot|Slurp|Baiduspider|BaiduImagespider|BaiduMobaider|YetiBot|Applebot/in
    expected_bots_only_re = / bot$/n
    assert_equal(expected_bots_re, bots_re)
    assert_equal(expected_default_bots_re, default_bots_re)
    assert_equal(expected_bots_only_re, bots_only_re)
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
end
