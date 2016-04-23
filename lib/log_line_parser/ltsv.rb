#!/usr/bin/env ruby

module LogLineParser
  module Ltsv
    LABEL_SEPARATOR = ":"
    TAB = "\t"

    ##
    # Label names are borrowed from
    # http://ltsv.org/

    FORMAT_STRING_LABEL_TABLE = {
      "%t" => "time",
      "%h" => "host",
      "%{X-Forwarded-For}i" => "forwardedfor",
      "%l" => "ident",
      "%u" => "user",
      "%r" => "req",
      "%m" => "method",
      "%U%q" => "uri",
      "%H" => "protocol",
      "%>s" => "status",
      "%B" => "size",
      "%b" => "size",
      "%I" => "reqsize",
      "%{Referer}i" => "referer",
      "%{User-agent}i" => "ua",
      "%{Host}i" => "vhost",
      "%D" => "reqtime_microsec",
      "%T" => "reqtime",
      "%{X-Cache}o" => "cache",
      "%{X-Runtime}o" => "runtime",
      # "-" => "apptime",
    }

    def self.format_strings_to_labels(format_strings)
      format_strings.map do |string|
        FORMAT_STRING_LABEL_TABLE[string]||string
      end
    end

    def self.to_ltsv(labels, values)
      fields = labels.zip(values).map {|field| field.join(LABEL_SEPARATOR) }
      fields.join(TAB)
    end
  end
end
