#!/usr/bin/env ruby
# coding: utf-8

require "uri"

iroha_utf8 = "いろは"
iroha_sjis = iroha_utf8.encode("Windows-31J")

{
  utf8: iroha_utf8,
  sjis: iroha_sjis
}.each do |k, v|
  puts "#{k}:"
  p v
  puts URI.encode_www_form_component(v)
end
