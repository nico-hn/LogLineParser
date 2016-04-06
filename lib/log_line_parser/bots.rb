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
      escaped_re = compile_escaped_re(bots_config)
      re = compile_re(bots_config)
      return Regexp.union(escaped_re, re) if escaped_re && re
      escaped_re || re
    end

    def self.compile_escaped_re(bots_config)
      bot_names = bots_config[ConfigLabels::BOTS] || []
      if bots_config[ConfigLabels::INHERIT_DEFAULT_BOTS]
        bot_names = (DEFAULT_BOTS + bot_names).uniq
      end
      return if bot_names.empty?
      escaped_bots_str = bot_names.map {|name| Regexp.escape(name) }.join("|")
      Regexp.compile(escaped_bots_str, Regexp::IGNORECASE, "n")
    end

    def self.compile_re(bots_config)
      bots_pats = bots_config[ConfigLabels::BOTS_RE]
      Regexp.compile(bots_pats.join("|"), nil, "n") if bots_pats
    end

    private_class_method :compile_escaped_re, :compile_re

    DEFAULT_RE = compile_bots_re
  end
end
