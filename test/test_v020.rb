# frozen_string_literal: true

require "test_helper"

class TestV020 < Minitest::Test
  def setup
    @tokenizer = TokenizerRuby::Tokenizer.from_pretrained("bert-base-uncased")
  end

  # --- Issue #1: Thread safety (Mutex instead of RefCell) ---

  def test_concurrent_encode
    threads = 10.times.map do
      Thread.new do
        5.times { @tokenizer.encode("Thread safety test") }
      end
    end
    threads.each(&:join)
    # If we got here without panic, thread safety works
    assert true
  end

  def test_concurrent_encode_and_decode
    threads = []
    threads << Thread.new { 10.times { @tokenizer.encode("Hello world") } }
    threads << Thread.new { 10.times { @tokenizer.decode([101, 7592, 2088, 102]) } }
    threads << Thread.new { 10.times { @tokenizer.vocab_size } }
    threads.each(&:join)
    assert true
  end

  # --- Issue #2: Error subclasses ---

  def test_error_hierarchy
    assert TokenizerRuby::Error < StandardError
    assert TokenizerRuby::TokenizationError < TokenizerRuby::Error
    assert TokenizerRuby::FileNotFoundError < TokenizerRuby::Error
    assert TokenizerRuby::ConfigurationError < TokenizerRuby::Error
  end

  def test_encode_non_string_raises_error
    assert_raises(TokenizerRuby::Error) { @tokenizer.encode(123) }
  end

  def test_decode_non_array_raises_error
    assert_raises(TokenizerRuby::Error) { @tokenizer.decode("not array") }
  end

  def test_truncate_negative_raises_configuration_error
    assert_raises(TokenizerRuby::ConfigurationError) do
      @tokenizer.truncate("hi", max_tokens: -1)
    end
  end

  # --- Issue #3: add_special_tokens parameter ---

  def test_encode_with_special_tokens
    with = @tokenizer.encode("Hello", add_special_tokens: true)
    without = @tokenizer.encode("Hello", add_special_tokens: false)

    # BERT adds [CLS] and [SEP], so with_special should be longer
    assert with.length > without.length
    # [CLS] = 101, [SEP] = 102 for bert-base-uncased
    assert_equal 101, with.ids.first
    assert_equal 102, with.ids.last
  end

  def test_encode_default_no_special_tokens
    encoding = @tokenizer.encode("Hello")
    # Default should not add special tokens (backward compatible)
    refute_equal 101, encoding.ids.first
  end

  def test_encode_batch_with_special_tokens
    with = @tokenizer.encode_batch(["Hello", "World"], add_special_tokens: true)
    without = @tokenizer.encode_batch(["Hello", "World"], add_special_tokens: false)

    with.each do |enc|
      assert_equal 101, enc.ids.first
      assert_equal 102, enc.ids.last
    end
    without.each do |enc|
      refute_equal 101, enc.ids.first
    end
  end

  # --- Issue #4: skip_special_tokens parameter ---

  def test_decode_skip_special_tokens
    encoding = @tokenizer.encode("Hello world", add_special_tokens: true)
    with_skip = @tokenizer.decode(encoding.ids, skip_special_tokens: true)
    without_skip = @tokenizer.decode(encoding.ids, skip_special_tokens: false)

    refute_includes with_skip, "[CLS]"
    assert_includes without_skip, "[CLS]"
  end

  def test_decode_batch_skip_special_tokens
    encodings = @tokenizer.encode_batch(["Hello", "World"], add_special_tokens: true)
    ids_array = encodings.map(&:ids)

    with_skip = @tokenizer.decode_batch(ids_array, skip_special_tokens: true)
    without_skip = @tokenizer.decode_batch(ids_array, skip_special_tokens: false)

    with_skip.each { |text| refute_includes text, "[CLS]" }
    without_skip.each { |text| assert_includes text, "[CLS]" }
  end

  # --- Issue #5: disable_truncation and disable_padding ---

  def test_disable_truncation
    @tokenizer.enable_truncation(max_length: 3)
    encoding = @tokenizer.encode("This is a longer sentence for testing")
    assert encoding.length <= 3

    @tokenizer.disable_truncation
    encoding2 = @tokenizer.encode("This is a longer sentence for testing")
    assert encoding2.length > 3
  end

  def test_disable_padding
    @tokenizer.enable_padding(length: 10)
    encoding = @tokenizer.encode("Hi")
    assert_equal 10, encoding.length

    @tokenizer.disable_padding
    encoding2 = @tokenizer.encode("Hi")
    assert encoding2.length < 10
  end

  # --- Issue #6: type_ids, special_tokens_mask, word_ids ---

  def test_encoding_type_ids
    encoding = @tokenizer.encode("Hello world", add_special_tokens: true)
    assert_kind_of Array, encoding.type_ids
    assert_equal encoding.length, encoding.type_ids.length
    encoding.type_ids.each { |t| assert_kind_of Integer, t }
  end

  def test_encoding_special_tokens_mask
    encoding = @tokenizer.encode("Hello world", add_special_tokens: true)
    assert_kind_of Array, encoding.special_tokens_mask
    assert_equal encoding.length, encoding.special_tokens_mask.length
    # [CLS] and [SEP] should be marked as special (1), others as 0
    assert_equal 1, encoding.special_tokens_mask.first
    assert_equal 1, encoding.special_tokens_mask.last
    assert encoding.special_tokens_mask[1..-2].all? { |m| m == 0 }
  end

  def test_encoding_word_ids
    encoding = @tokenizer.encode("Hello world", add_special_tokens: true)
    assert_kind_of Array, encoding.word_ids
    assert_equal encoding.length, encoding.word_ids.length
    # [CLS] and [SEP] should have nil word_ids
    assert_nil encoding.word_ids.first
    assert_nil encoding.word_ids.last
  end

  def test_encoding_without_special_tokens_has_word_ids
    encoding = @tokenizer.encode("Hello world")
    assert_kind_of Array, encoding.word_ids
    encoding.word_ids.each { |w| assert_kind_of Integer, w }
  end

  # --- Issue #7: BERT and edge case tests ---

  def test_bert_tokenizer
    encoding = @tokenizer.encode("Hello, world!")
    assert encoding.length.positive?
    # BERT lowercases for uncased model
    encoding.tokens.each { |t| assert_equal t, t.downcase }
  end

  def test_bert_subword_tokenization
    encoding = @tokenizer.encode("tokenization")
    # "tokenization" gets split into ["token", "##ization"]
    assert encoding.tokens.any? { |t| t.start_with?("##") }
  end

  def test_bert_roundtrip
    text = "The quick brown fox"
    encoding = @tokenizer.encode(text)
    decoded = @tokenizer.decode(encoding.ids)
    assert_equal text.downcase, decoded.strip.downcase
  end

  def test_empty_string
    encoding = @tokenizer.encode("")
    assert_equal 0, encoding.length
  end

  def test_unicode_text
    encoding = @tokenizer.encode("こんにちは世界")
    assert encoding.length.positive?
  end

  def test_long_text
    text = "word " * 1000
    encoding = @tokenizer.encode(text)
    assert encoding.length.positive?
  end

  def test_special_characters
    encoding = @tokenizer.encode("Hello! @#$%^&*() World")
    assert encoding.length.positive?
  end

  def test_newlines_and_tabs
    encoding = @tokenizer.encode("Hello\nWorld\tFoo")
    assert encoding.length.positive?
  end
end

class TestLlamaTokenizer < Minitest::Test
  def setup
    @tokenizer = TokenizerRuby::Tokenizer.from_pretrained("hf-internal-testing/llama-tokenizer")
  end

  def test_llama_encode
    encoding = @tokenizer.encode("Hello, world!")
    assert encoding.length.positive?
  end

  def test_llama_roundtrip
    text = "The quick brown fox jumps over the lazy dog"
    encoding = @tokenizer.encode(text)
    decoded = @tokenizer.decode(encoding.ids)
    assert_equal text, decoded.strip
  end

  def test_llama_vocab_size
    size = @tokenizer.vocab_size
    assert size > 30000
  end
end
