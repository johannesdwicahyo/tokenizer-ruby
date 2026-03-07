# frozen_string_literal: true

require "test_helper"

class TestEncoding < Minitest::Test
  def test_encoding_attributes
    encoding = TokenizerRuby::Encoding.new(
      ids: [1, 2, 3],
      tokens: ["a", "b", "c"],
      offsets: [[0, 1], [1, 2], [2, 3]],
      attention_mask: [1, 1, 1]
    )

    assert_equal [1, 2, 3], encoding.ids
    assert_equal ["a", "b", "c"], encoding.tokens
    assert_equal [[0, 1], [1, 2], [2, 3]], encoding.offsets
    assert_equal [1, 1, 1], encoding.attention_mask
    assert_equal 3, encoding.length
  end

  def test_encoding_length
    encoding = TokenizerRuby::Encoding.new(
      ids: [],
      tokens: [],
      offsets: [],
      attention_mask: []
    )
    assert_equal 0, encoding.length
  end
end
