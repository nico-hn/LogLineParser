#!/usr/bin/env ruby

module LogLineParser
  module Bots
    module ConfigLabels
      INHERIT_DEFAULT_BOTS = "inherit_default_bots"
      BOTS = "bots"
      BOTS_RE = "bots_re"
    end

    DEFAULT_BOTS = %w(
Googlebot
Googlebot-Mobile
Mediapartners-Google
Bingbot
Slurp
Baiduspider
BaiduImagespider
BaiduMobaider
YetiBot
Applebot
)

    DEFAULT_CONFIG = {
      ConfigLabels::INHERIT_DEFAULT_BOTS => true,
      ConfigLabels::BOTS => [],
      ConfigLabels::BOTS_RE => nil
    }

    def self.compile_bots_re(bots_config=DEFAULT_CONFIG)
      bot_names = bots_config[ConfigLabels::BOTS] || []
      if bots_config[ConfigLabels::INHERIT_DEFAULT_BOTS]
        bot_names = (DEFAULT_BOTS + bot_names).uniq
      end
      escaped_bots_str = bot_names.map {|name| Regexp.escape(name) }.join("|")
      escaped_re = Regexp.compile(escaped_bots_str, Regexp::IGNORECASE, "n")
      bots_pats = bots_config[ConfigLabels::BOTS_RE]
      return escaped_re unless bots_pats
      re = Regexp.compile(bots_pats.join("|"), nil, "n")
      Regexp.union(escaped_re, re)
    end

    DEFAULT_RE = compile_bots_re
  end
end
