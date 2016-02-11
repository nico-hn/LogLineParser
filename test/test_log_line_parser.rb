require 'minitest_helper'

class TestLogLineParser < Minitest::Test
  def setup
    @log_line = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/start.html" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
    @log_line2 = '192.168.3.4 - quidam [07/Feb/2016:07:39:42 +0900] "GET /index.html HTTP/1.1" 200 432 "http://www.example.org/" "Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0"'
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

  def test_combined_log_record
    record = LogLineParser.parse(@log_line).to_record
    record2 = LogLineParser.parse(@log_line2).to_record
    expected_user_agent = 'Mozilla/5.0 (X11; U; Linux i686; ja-JP; rv:1.7.5) Gecko/20041108 Firefox/1.0'
    expected_last_request_status = 200
    expected_time = "2016-02-07 07:39:42 +0900"
    assert_equal(expected_user_agent, record.user_agent)
    assert_equal(expected_last_request_status, record.last_request_status)
    assert_equal(expected_time, record.time.to_s)
    assert_equal("GET", record.method)
    assert_equal("http://www.example.org/", record.referer_url)
    assert_equal("/start.html", record.referer_resource)
    assert_equal("/", record2.referer_resource)
  end

  def test_combined_log_record_date
    record = LogLineParser.parse(@log_line).to_record
    assert_equal("20160207", record.date.strftime("%Y%m%d"))
  end
end
