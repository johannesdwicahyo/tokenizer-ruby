# frozen_string_literal: true

require "test_helper"

class TestTokenizer < Minitest::Test
  def setup
    @tokenizer = TokenizerRuby::Tokenizer.from_pretrained("gpt2")
  end

  def test_from_pretrained
    assert_instance_of TokenizerRuby::Tokenizer, @tokenizer
  end

  def test_encode
    encoding = @tokenizer.encode("Hello, world!")
    assert_instance_of TokenizerRuby::Encoding, encoding
    assert_kind_of Array, encoding.ids
    assert_kind_of Array, encoding.tokens
    assert encoding.length.positive?
  end

  def test_encode_known_output
    encoding = @tokenizer.encode("Hello")
    assert_includes encoding.tokens, "Hello"
  end

  def test_decode
    encoding = @tokenizer.encode("Hello, world!")
    decoded = @tokenizer.decode(encoding.ids)
    assert_equal "Hello, world!", decoded
  end

  def test_encode_batch
    encodings = @tokenizer.encode_batch(["Hello", "World"])
    assert_equal 2, encodings.length
    assert_instance_of TokenizerRuby::Encoding, encodings[0]
    assert_instance_of TokenizerRuby::Encoding, encodings[1]
  end

  def test_decode_batch
    encodings = @tokenizer.encode_batch(["Hello", "World"])
    ids_array = encodings.map(&:ids)
    decoded = @tokenizer.decode_batch(ids_array)
    assert_equal 2, decoded.length
    assert_equal "Hello", decoded[0]
    assert_equal "World", decoded[1]
  end

  def test_vocab_size
    size = @tokenizer.vocab_size
    assert_equal 50257, size
  end

  def test_token_to_id
    id = @tokenizer.token_to_id("hello")
    assert_kind_of Integer, id
  end

  def test_id_to_token
    id = @tokenizer.token_to_id("hello")
    token = @tokenizer.id_to_token(id)
    assert_equal "hello", token
  end

  def test_token_to_id_unknown
    result = @tokenizer.token_to_id("this_token_definitely_does_not_exist_xyz")
    assert_nil result
  end

  def test_count
    count = @tokenizer.count("Hello, world!")
    assert count.positive?
    encoding = @tokenizer.encode("Hello, world!")
    assert_equal encoding.length, count
  end

  def test_truncate
    text = "This is a longer sentence that should be truncated to fewer tokens"
    truncated = @tokenizer.truncate(text, max_tokens: 3)
    count = @tokenizer.count(truncated)
    assert count <= 3
  end

  def test_unicode
    encoding = @tokenizer.encode("こんにちは世界")
    assert encoding.length.positive?
    decoded = @tokenizer.decode(encoding.ids)
    assert_equal "こんにちは世界", decoded
  end

  def test_empty_string
    encoding = @tokenizer.encode("")
    assert_equal 0, encoding.length
    assert_equal [], encoding.ids
  end

  def test_encoding_offsets
    encoding = @tokenizer.encode("Hello, world!")
    assert_kind_of Array, encoding.offsets
    encoding.offsets.each do |offset|
      assert_equal 2, offset.length
      assert offset[0] <= offset[1]
    end
  end

  def test_encoding_attention_mask
    encoding = @tokenizer.encode("Hello, world!")
    assert_kind_of Array, encoding.attention_mask
    encoding.attention_mask.each do |mask|
      assert_includes [0, 1], mask
    end
  end

  def test_new_with_path
    mock_inner = Minitest::Mock.new
    TokenizerRuby::InternalTokenizer.stub(:from_file, mock_inner) do
      tokenizer = TokenizerRuby::Tokenizer.new("/some/path/tokenizer.json")
      assert_instance_of TokenizerRuby::Tokenizer, tokenizer
    end
  end

  def test_encode_nil_raises_error
    assert_raises(TokenizerRuby::Error) do
      @tokenizer.encode(nil)
    end
  end

  def test_encode_non_string_raises_error
    assert_raises(TokenizerRuby::Error) do
      @tokenizer.encode(123)
    end
  end

  def test_decode_non_array_raises_error
    assert_raises(TokenizerRuby::Error) do
      @tokenizer.decode("not array")
    end
  end

  def test_truncate_negative_max_tokens_raises
    assert_raises(TokenizerRuby::Error) do
      @tokenizer.truncate("hi", max_tokens: -1)
    end
  end

  def test_encoding_has_type_ids_attribute
    encoding = @tokenizer.encode("Hello")
    assert_respond_to encoding, :type_ids
  end

  def test_encoding_has_special_tokens_mask
    encoding = @tokenizer.encode("Hello")
    assert_respond_to encoding, :special_tokens_mask
  end

  def test_encoding_has_word_ids
    encoding = @tokenizer.encode("Hello")
    assert_respond_to encoding, :word_ids
  end
end
