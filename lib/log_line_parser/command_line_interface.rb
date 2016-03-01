#!/usr/bin/env ruby

require 'yaml'
require 'optparse'

module LogLineParser
  module CommandLineInterFace
    def self.read_configs(config)
      YAML.load_stream(config).to_a
    end

  end
end
