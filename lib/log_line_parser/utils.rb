#!/usr/bin/env ruby

module LogLineParser
  module Utils
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
)

    def self.compile_bots_re(bot_names=DEFAULT_BOTS)
      bots_str = bot_names.map {|name| Regexp.escape(name) }.join("|")
      Regexp.compile(bots_str, Regexp::IGNORECASE)
    end

    DEFAULT_BOTS_RE = compile_bots_re

    def self.access_by_bots?(record, bots_re=DEFAULT_BOTS_RE)
      bots_re =~ record.user_agent
    end

    def self.referred_from?(record, host_name, resources=[])
      target_host = (record.referer_host == host_name)
      return target_host if resources.empty?
      target_host and resources.include?(record.referer_resource)
    end

    def self.access_to_resources?(record, resources=[])
      resources.include?(record.resource)
    end

    def self.open_multiple_output_files(base_names, dir=nil, ext="log")
      logs = {}
      filepath = dir ? File.join(dir, "%s.#{ext}") : "%s.#{ext}"
      base_names.each do |base|
        logs[base] = open(format(filepath, base), "w")
      end
      yield logs
    ensure
      logs.each do |k, v|
        v.close
      end
    end
  end
end
