require 'minitest_helper'

class TestLogLineParser < Minitest::Test
  def setup
    @common_log_line = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432'
    @log_line = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/start.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line2 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line3 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /subdir/index.html HTTP/1.1" 200 432 "http://www.example.org" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line4 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /subdir/index.html HTTP/1.1" 200 432 "http://www.example.org/subdir/" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @irregular_log_line = 'sub_domain-192-168-0-1.example.org - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "/dir/start.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
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
  end

  def test_that_it_has_a_version_number
    refute_nil ::LogLineParser::VERSION
  end

  def test_log_line_tokenizer_tokenize
    [[
        "192.168.0.1 - - [time ]",
        ["192.168.0.1", " ", "-", " ", "-", " ", "[", "time", " ", "]"]
      ],
      [
        "192.168.0.1 - - [time ]  123",
        ["192.168.0.1", " ", "-", " ", "-", " ", "[", "time", " ", "]", "  ", "123"]
      ]
    ].each do |str, expected|
      tokens = LogLineParser::LogLineTokenizer.tokenize(str)
      assert_equal(expected, tokens)
    end
  end

  def test_log_line_node_stack
    line = '192.168.3.4 - - [time string] - "string value" -'
    stack = LogLineParser::LogLineNodeStack.new
    tokens = LogLineParser::LogLineTokenizer.tokenize(line)
    expected = ["192.168.3.4", "-", "-", "time string", "-", "string value", "-"]

    tokens.each do |token|
      stack.push token
    end

    result = stack.root.subnodes.map {|val| val.to_s }
    assert_equal(expected, result)
  end

  def test_log_line_node_stack2
    line = 'sub_domain-192-168-0-1.example.org - - [time string] - "string value" -'
    stack = LogLineParser::LogLineNodeStack.new
    tokens = LogLineParser::LogLineTokenizer.tokenize(line)
    expected = ["sub_domain-192-168-0-1.example.org", "-", "-", "time string", "-", "string value", "-"]

    tokens.each do |token|
      stack.push token
    end

    result = stack.root.subnodes.map {|val| val.to_s }
    assert_equal(expected, result)
  end


  def test_escape_in_string_node
    line = '192.168.3.4 - - [time string] - "string \\tvalue" -'
    stack = LogLineParser::LogLineNodeStack.new
    tokens = LogLineParser::LogLineTokenizer.tokenize(line)
    expected = ["192.168.3.4", "-", "-", "time string", "-", "string \tvalue", "-"]

    tokens.each do |token|
      stack.push token
    end

    result = stack.root.subnodes.map {|val| val.to_s }
    assert_equal(expected, result)
  end

  def test_escape_node_to_be_escaped_re
    re = LogLineParser::StringEscapeNode.to_be_escaped_re
    assert_equal(/\A(?:\\|"|t|n|r)/, re)
  end

  def test_escape_node_remove_escaped_part
    escape_node = LogLineParser::StringEscapeNode.new
    string_with_a_tab = "string that begins with a tab"
    string_with_a_double_quote = "string with a double quote"
    assert_equal(string_with_a_tab,
                 escape_node.remove_escaped_part("t" + string_with_a_tab))
    assert_equal(string_with_a_double_quote,
                 escape_node.remove_escaped_part('"' + string_with_a_double_quote))
  end

  def test_escape_node_part_to_be_escaped
    escape_node = LogLineParser::StringEscapeNode.new
    double_quote = '"a string that begins with a double quote'
    should_not_be_escaped = "a string"
    assert_equal('"', escape_node.part_to_be_escaped(double_quote))
    assert_equal(nil, escape_node.part_to_be_escaped(should_not_be_escaped))
  end

  def test_log_line_node_stack_to_a
    line = '192.168.3.4 - - [time string] - "string \\tvalue" -'
    expected = ["192.168.3.4", "-", "-", "time string", "-", "string \tvalue", "-"]
    result = LogLineParser.parse(line).to_a
    assert_equal(expected, result)
  end

  def test_log_line_node_stack_to_hash
    h = LogLineParser.parse(@log_line).to_hash
    assert_equal(@log_line_hash, h)
  end

  def test_common_log_record
    record = LogLineParser::CommonLogParser.parse(@common_log_line)
    expected_last_request_status = 200

    assert_equal(expected_last_request_status, record.last_request_status)
  end

  def test_combined_log_record
    default_parse_time_value = LogLineParser::CombinedLogParser.parse_time_value
    LogLineParser::CombinedLogParser.parse_time_value = true
    record = LogLineParser.parse(@log_line).to_record
    record2 = LogLineParser.parse(@log_line2).to_record
    record3 = LogLineParser.parse(@log_line3).to_record
    expected_user_agent = 'Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0'
    expected_last_request_status = 200
    expected_time = "2016-02-07 07:39:42 +0900"
    assert_equal(expected_user_agent, record.user_agent)
    assert_equal(expected_last_request_status, record.last_request_status)
    assert_equal(expected_time, record.time.to_s)
    assert_equal("GET", record.method)
    assert_equal("www.example.org", record.referer_host)
    assert_equal("http:", record.referer_scheme)
    assert_equal("/start.html", record.referer_resource)
    assert_equal("/", record2.referer_resource)
    assert_equal("/", record3.referer_resource)
    LogLineParser::CombinedLogParser.parse_time_value = default_parse_time_value
  end

  def test_combined_log_record_to_hash
    h = LogLineParser::CombinedLogParser.to_hash(@log_line)
    assert_equal(@log_line_hash, h)
  end

  def test_combined_log_record_parse_time
    parse_time_enabled = LogLineParser::CombinedLogParser.parse_time_value
    expected_time_str = "07/Feb/2016:07:39:42 +0900"
    expected_time = "2016-02-07 07:39:42 +0900"

    LogLineParser::CombinedLogParser.parse_time_value = false
    record = LogLineParser.parse(@log_line).to_record
    assert_equal(expected_time_str, record.time.to_s)

    LogLineParser::CombinedLogParser.parse_time_value = true
    record = LogLineParser.parse(@log_line).to_record
    assert_equal(expected_time, record.time.to_s)

    LogLineParser::CombinedLogParser.parse_time_value = parse_time_enabled
  end

  def test_combined_log_record_date
    default_parse_time_value = LogLineParser::CombinedLogParser.parse_time_value
    LogLineParser::CombinedLogParser.parse_time_value = true
    record = LogLineParser.parse(@log_line).to_record
    assert_equal("20160207", record.date.strftime("%Y%m%d"))
    LogLineParser::CombinedLogParser.parse_time_value = default_parse_time_value
  end

  def test_combined_log_record_parse
    default_parse_time_value = LogLineParser::CombinedLogParser.parse_time_value
    LogLineParser::CombinedLogParser.parse_time_value = true
    record = LogLineParser::CombinedLogParser.parse(@log_line)
    record2 = LogLineParser::CombinedLogParser.parse(@log_line2)
    expected_user_agent = 'Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0'
    expected_last_request_status = 200
    expected_time = "2016-02-07 07:39:42 +0900"
    assert_equal(expected_user_agent, record.user_agent)
    assert_equal(expected_last_request_status, record.last_request_status)
    assert_equal(expected_time, record.time.to_s)
    assert_equal("GET", record.method)
    assert_equal("www.example.org", record.referer_host)
    assert_equal("/start.html", record.referer_resource)
    assert_equal("/", record2.referer_resource)
    LogLineParser::CombinedLogParser.parse_time_value = default_parse_time_value
  end

  def test_combined_log_record_referred_from_host
    record = LogLineParser::CombinedLogParser.parse(@log_line)
    assert_equal(true,record.referred_from_host?("www.example.org"))
    assert_equal(false,record.referred_from_host?("www.example.com"))
  end

  def test_irregular_record
    record = LogLineParser::CombinedLogParser.parse(@irregular_log_line)
    assert_equal("sub_domain-192-168-0-1.example.org", record.remote_host)
    assert_equal("", record.referer_host)
    assert_equal("/dir/start.html", record.referer_resource)
  end

  def test_mal_formed_record_error
    err = assert_raises(LogLineParser::MalFormedRecordError) do
      LogLineParser::CombinedLogParser.parse(@mal_formed_log_line)
    end

    assert_equal(@mal_formed_log_line, err.message)
  end
end
