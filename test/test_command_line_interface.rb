#!/usr/bin/env ruby

require 'minitest_helper'
require 'log_line_parser/command_line_interface'
require 'shellwords'

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
    setup_argv("--filter=config.yaml")
    opts = CommandLineInterFace.parse_options
    expected_result =  { :config_file => "config.yaml" }
    assert_equal(expected_result, opts)

    setup_argv("--convert=csv")
    opts = CommandLineInterFace.parse_options
    expected_result =  { :format => "csv" }
    assert_equal(expected_result, opts)
  end
end
