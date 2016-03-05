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
    @log_line6 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /subdir/non-existent.html HTTP/1.1" 404 432 "http://www.example.org/subdir/example.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @googlebot = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"'
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

  def test_status_code_404?
    record = LogLineParser::CombinedLogRecord.parse(@log_line)
    record6 = LogLineParser::CombinedLogRecord.parse(@log_line6)
    query = Query.new(domain: "www.example.org", resources: ["/subdir/non-existent.html"])
    assert_equal(false, query.status_code_404?(record))
    assert_equal(true, query.status_code_404?(record6))
  end

  def test_access_by_bots?
    bot_record = CombinedLogRecord.parse(@googlebot)
    normal_record = CombinedLogRecord.parse(@log_line)
    assert(Query.access_by_bots?(bot_record))
    assert_nil(Query.access_by_bots?(normal_record))
  end

  def test_query_referred_from?
    record = LogLineParser::CombinedLogRecord.parse(@log_line)
    assert_equal(true, Query.referred_from?(record, ["/start.html"]))
    assert_equal(false, Query.referred_from?(record, ["/non-existent.html"]))
  end

  def test_query_referred_from_under?
    record = LogLineParser::CombinedLogRecord.parse(@log_line4)
    assert_equal(true, Query.referred_from_under?(record, "/"))
    assert_equal(true, Query.referred_from_under?(record, "/subdir/"))
    assert_equal(false, Query.referred_from_under?(record, "/non-existent/"))
  end

  def test_query_access_to_resources?
    record = LogLineParser::CombinedLogRecord.parse(@log_line)
    assert_equal(true, Query.access_to_resources?(record, ["/index.html"]))
    assert_equal(false, Query.access_to_resources?(record, ["/start.html"]))
  end

  def test_query_access_to_resources_under?
    record = LogLineParser::CombinedLogRecord.parse(@log_line3)
    assert_equal(true, Query.access_to_resources_under?(record, "/subdir/"))
    assert_equal(true, Query.access_to_resources_under?(record, "/"))
    assert_equal(false, Query.access_to_resources_under?(record, "/non-existent"))
  end

  def test_query_register_query_to_log
    option_any = {
      "host_name" => "www.example.org",
      "resources" => [
        "/start.html",
        "/subdir/index.html"
      ],
      "queries" => [:access_to_resources?, :referred_from_resources?],
      "output_log_name" => "log_file_any",
      "query_type" => "any"
    }

    option_all = option_any.dup
    option_all["query_type"] = "all"
    option_all["output_log_name"] = "log_file_all"

    logs = {}
    logs["log_file_any"] = StringIO.new(String.new, "w")
    logs["log_file_all"] = StringIO.new(String.new, "w")

    query_log_any = Query.register_query_to_log(option_any, logs)
    query_log_all = Query.register_query_to_log(option_all, logs)

    [@log_line, @log_line4].each do |line|
      record = LogLineParser::CombinedLogRecord.parse(line)
      query_log_any.call(line, record)
      query_log_all.call(line, record)
    end

    assert_equal(@log_line + @log_line4, logs["log_file_any"].string)
    assert_equal("", logs["log_file_all"].string)
  end

  def test_not_allowable_method_error
    option_any = {
      "host_name" => "www.example.org",
      "resources" => [
        "/start.html",
        "/subdir/index.html"
      ],
      "queries" => [:access_to_resources?, :referred_from_resources?, :unknown_query],
      "output_log_name" => "log_file_any",
      "query_type" => "any"
    }

    logs = { "log_file_any" =>  StringIO.new(String.new, "w") }

    assert_raises(Query::NotAllowableMethodError) do
      Query.register_query_to_log(option_any, logs)
    end
  end
end
