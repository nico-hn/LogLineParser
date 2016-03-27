#!/usr/bin/env ruby

require 'log_line_parser'
require 'log_line_parser/utils'

module LogLineParser

  # MoeLogFormat and MoeLogParser is added from the personal needs of the
  # original author, and the log format is not a widely used one.
  # You may remove this file if you don't need it.
  # (MOE is the acronym of the name of the organization for which
  # the author is working at the time of the first release of this program.)
  #
  # CombinedLogFormat + "%D"
  MoeLogFormat = "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %D"
  MoeLogParser = parser(MoeLogFormat)
  PREDEFINED_FORMATS['moe'] = MoeLogParser
end

