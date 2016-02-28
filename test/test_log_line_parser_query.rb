#!/usr/bin/env ruby

require 'minitest_helper'


class TestLogLineParserQuery < Minitest::Test
  include LogLineParser

  def setup
    @log_line = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/start.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line2 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line3 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /subdir/index.html HTTP/1.1" 200 432 "http://www.example.org" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line4 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /subdir/index.html HTTP/1.1" 200 432 "http://www.example.org/subdir/" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line5 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /subdir/index.html HTTP/1.1" 200 432 "http://www.example.org/subdir/example.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
  end

  def test_referred_from_resources?
    record = CombinedLogRecord.parse(@log_line)
    record2 = CombinedLogRecord.parse(@log_line2)
    query = Query.new(domain: "www.example.org", resources: ["/start.html"])
    query_without_domain = Query.new(resources: ["/start.html"])
    assert_equal(true, query.referred_from_resources?(record))
    assert_equal(true, query_without_domain.referred_from_resources?(record))
    assert_equal(false, query.referred_from_resources?(record2))
  end

  def test_referred_from_under_resources?
    record = CombinedLogRecord.parse(@log_line)
    record3 = CombinedLogRecord.parse(@log_line3)
    record4 = CombinedLogRecord.parse(@log_line4)
    record5 = CombinedLogRecord.parse(@log_line5)
    query = Query.new(domain: "www.example.org", resources: ["/subdir/"])
    query2 = Query.new(domain: "www.example.org", resources: ["/"])
    assert_equal(false, query.referred_from_under_resources?(record))
    assert_equal(true, query.referred_from_under_resources?(record4))
    assert_equal(true, query.referred_from_under_resources?(record5))
    assert_equal(true, query2.referred_from_under_resources?(record3))
    assert_equal(true, query2.referred_from_under_resources?(record5))
  end

  def test_access_to_resources?
    record = CombinedLogRecord.parse(@log_line)
    record3 = CombinedLogRecord.parse(@log_line3)
    query = Query.new(domain: "www.example.org", resources: ["/index.html"])
    query2 = Query.new(domain: "www.example.org", resources: ["/non-existent.html"])
    query3 = Query.new(domain: "www.example.org", resources: ["/subdir/index.html"])
    assert_equal(true, query.access_to_resources?(record))
    assert_equal(false, query2.access_to_resources?(record))
    assert_equal(true, query3.access_to_resources?(record3))
  end

  def test_access_to_under_resources?
    record = CombinedLogRecord.parse(@log_line)
    record3 = CombinedLogRecord.parse(@log_line3)
    query = Query.new(domain: "www.example.org", resources: ["/"])
    query2 = Query.new(domain: "www.example.org", resources: ["/non-existent.html"])
    query3 = Query.new(domain: "www.example.org", resources: ["/subdir/"])
    assert_equal(true, query.access_to_under_resources?(record))
    assert_equal(false, query2.access_to_under_resources?(record))
    assert_equal(false, query2.access_to_under_resources?(record3))
    assert_equal(true, query.access_to_under_resources?(record3))
    assert_equal(false, query3.access_to_under_resources?(record))
    assert_equal(true, query3.access_to_under_resources?(record3))
  end
end
