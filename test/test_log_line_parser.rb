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
end
