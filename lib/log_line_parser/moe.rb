#!/usr/bin/env ruby

require 'log_line_parser'
require 'log_line_parser/utils'

# MoeLogParser is added from the personal needs of the original author,
# and the LogFormat for it is not a widely used format.
# You may remove this file if you don't need it.
# (MOE is the acronym of the organization's name for which the author
# is working at the time of the first release of this program.)

module LogLineParser
  # CombinedLogFormat + "%D"
  MoeLogFormat = "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\" %D"
  MoeLogParser = parser(MoeLogFormat)
  PREDEFINED_FORMATS['moe'] = MoeLogParser
end

