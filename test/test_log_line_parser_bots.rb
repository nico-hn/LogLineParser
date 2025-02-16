#!/usr/bin/env ruby

require 'minitest_helper'
require 'log_line_parser/bots'

class TestLogLineParserUtils < Minitest::Test
  include LogLineParser

  def test_bots_compile_bots_re_utf8
    bots_re = Bots.compile_bots_re
    iroha_utf8 = "%E3%81%84%E3%82%8D%E3%81%AF"

    # assert_match(bots_re, iroha_utf8)
    refute_match(bots_re, iroha_utf8)
  end

  def test_bots_compile_bots_re_sjis
    bots_re = Bots.compile_bots_re
    iroha_sjis = "\x82\xA2\x82\xEB\x82\xCD".force_encoding("Windows-31J")

    # assert_match(bots_re, iroha_sjis)
    refute_match(bots_re, iroha_sjis)
  end
end
