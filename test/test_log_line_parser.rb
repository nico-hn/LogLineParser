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
end
