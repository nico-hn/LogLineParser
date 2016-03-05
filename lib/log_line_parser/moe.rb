#!/usr/bin/env ruby

require 'log_line_parser'
require 'log_line_parser/utils'

module LogLineParser
  # CombinedLogFormat + "%D"
  MoeLogFormat = "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %D"
  MoeLogParser = parser(MoeLogFormat)
  PREDEFINED_FORMATS['moe'] = MoeLogParser
end

