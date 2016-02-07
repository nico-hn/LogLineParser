require 'minitest_helper'

class TestLogLineParser < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::LogLineParser::VERSION
  end

  def test_tokenize_tokenize
    [[
        "192.168.0.1 - - [time ]",
        ["192.168.0.1", " ", "-", " ", "-", " ", "[", "time", " ", "]"]
      ],
      [
        "192.168.0.1 - - [time ]  123",
        ["192.168.0.1", " ", "-", " ", "-", " ", "[", "time", " ", "]", "  ", "123"]
      ]
    ].each do |str, expected|
      tokens = LogLineParser::Tokenizer.tokenize(str)
      assert_equal(expected, tokens)
    end
  end

  def test_log_line_node_stack
    line = '192.168.3.4 - - [time string] - "string value" -'
    stack = LogLineParser::LogLineNodeStack.new
    tokens = LogLineParser::Tokenizer.tokenize(line)
    expected = ["192.168.3.4", "-", "-", "time string", "-", "string value", "-"]

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
end
