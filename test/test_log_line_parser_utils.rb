#!/usr/bin/env ruby

require 'minitest_helper'
require 'log_line_parser/utils'

class TestLogLineParserUtils < Minitest::Test
  include LogLineParser

  def setup
    @common_log_line = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432'
    @log_line = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/start.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line2 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line3 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /subdir/index.html HTTP/1.1" 200 432 "http://www.example.org" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line4 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /subdir/index.html HTTP/1.1" 200 432 "http://www.example.org/subdir/" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @irregular_log_line = 'sub_domain-192-168-0-1.example.org - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "/dir/start.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line_with_a_tab_inside = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/start.html" "Mozilla/5.0\t(X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @googlebot = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"'
    @mal_formed_log_line = 'some thing wrong'
    @log_line_hash = {
      "%h" => "192.168.3.4",
      "%l" => "-",
      "%u" => "quidam",
      "%t" => "07/Feb/2016:07:39:42 +0900",
      "%r" => "GET /index.html HTTP/1.1",
      "%>s" => "200",
      "%b" => "432",
      "%{Referer}i" => "http://www.example.org/start.html",
      "%{User-agent}i" => "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0",
      "%m" => "GET",
      "%H" => "HTTP/1.1",
      "%U%q" => "/index.html"
    }

    @log_line_tsv = "192.168.3.4\t-\tquidam\t07/Feb/2016:07:39:42 +0900\tGET /index.html HTTP/1.1\t200\t432\thttp://www.example.org/start.html\tMozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"
    @log_line_with_a_tab_inside_tsv = "192.168.3.4\t-\tquidam\t07/Feb/2016:07:39:42 +0900\tGET /index.html HTTP/1.1\t200\t432\thttp://www.example.org/start.html\tMozilla/5.0\\t(X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"
    @log_line_csv = "192.168.3.4,-,quidam,07/Feb/2016:07:39:42 +0900,GET /index.html HTTP/1.1,200,432,http://www.example.org/start.html,Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0\n"
  end

  def test_utils_to_tsv
    tsv = Utils.to_tsv(@log_line)
    tsv_with_a_tab_inside = Utils.to_tsv(@log_line_with_a_tab_inside)
    assert_equal(@log_line_tsv, tsv)
    assert_equal(@log_line_with_a_tab_inside_tsv, tsv_with_a_tab_inside)
  end

  def test_utils_to_csv
    csv = Utils.to_csv(@log_line)
    assert_equal(@log_line_csv, csv)
  end

  def test_compile_bots_re_from_config_file
    bots_re = Utils.compile_bots_re_from_config_file("test/data/example_bots.yaml")
    default_bots_re = Utils.compile_bots_re_from_config_file(nil)
    bots_only_re = Utils.compile_bots_re_from_config_file("test/data/example_bots_re.yaml")
    expected_bots_re = /(?i-mx:Googlebot|Googlebot\-Mobile|Mediapartners\-Google|Bingbot|Slurp|Baiduspider|BaiduImagespider|BaiduMobaider|YetiBot|Applebot)|(?-mix: bot$)/
    expected_default_bots_re = /Googlebot|Googlebot\-Mobile|Mediapartners\-Google|Bingbot|Slurp|Baiduspider|BaiduImagespider|BaiduMobaider|YetiBot|Applebot/in
    expected_bots_only_re = / bot$/n
    assert_equal(expected_bots_re, bots_re)
    assert_equal(expected_default_bots_re, default_bots_re)
    assert_equal(expected_bots_only_re, bots_only_re)
  end
end
