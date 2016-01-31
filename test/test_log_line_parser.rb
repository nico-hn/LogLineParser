require 'minitest_helper'

class TestLogLineParser < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::LogLineParser::VERSION
  end

  def test_tokenize_tokenize
    str = "192.168.0.1 - - [time ]"
    tokens = LogLineParser::Tokenizer.tokenize(str)
    assert_equal(str, tokens)
  end

  def test_it_does_something_useful
    assert false
  end
end
