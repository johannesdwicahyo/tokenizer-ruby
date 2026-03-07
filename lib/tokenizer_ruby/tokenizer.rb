# frozen_string_literal: true

module TokenizerRuby
  class Tokenizer
    def self.from_pretrained(identifier)
      new(InternalTokenizer.from_pretrained(identifier))
    end

    def self.from_file(path)
      new(InternalTokenizer.from_file(path))
    end

    def encode(text)
      result = @inner._encode(text)
      Encoding.new(
        ids: result[:ids],
        tokens: result[:tokens],
        offsets: result[:offsets],
        attention_mask: result[:attention_mask]
      )
    end

    def decode(ids)
      @inner._decode(ids)
    end

    def encode_batch(texts)
      results = @inner._encode_batch(texts)
      results.map do |result|
        Encoding.new(
          ids: result[:ids],
          tokens: result[:tokens],
          offsets: result[:offsets],
          attention_mask: result[:attention_mask]
        )
      end
    end

    def decode_batch(ids_array)
      @inner._decode_batch(ids_array)
    end

    def vocab_size
      @inner.vocab_size
    end

    def token_to_id(token)
      @inner.token_to_id(token)
    end

    def id_to_token(id)
      @inner.id_to_token(id)
    end

    def count(text)
      encode(text).length
    end

    def truncate(text, max_tokens:)
      encoding = encode(text)
      return text if encoding.length <= max_tokens

      truncated_ids = encoding.ids[0, max_tokens]
      decode(truncated_ids)
    end

    def enable_truncation(max_length:)
      @inner._enable_truncation(max_length)
    end

    def enable_padding(length:, pad_token: "[PAD]")
      @inner._enable_padding(length, pad_token)
    end

    private

    def initialize(inner)
      @inner = inner
    end
  end
end
