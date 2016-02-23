#!/usr/bin/env ruby

require 'log_line_parser'
require 'log_line_parser/utils'

module LogLineParser
  MoeLogRecord = create_record_type(Fields::COMBINED + [:time_taken])
end

