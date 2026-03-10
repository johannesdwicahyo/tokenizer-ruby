# frozen_string_literal: true

module TokenizerRuby
  class Tokenizer
    def initialize(path_or_internal)
      if path_or_internal.is_a?(String)
        @inner = InternalTokenizer.from_file(path_or_internal)
      else
        @inner = path_or_internal
      end
    end

    def self.from_pretrained(identifier)
      new(InternalTokenizer.from_pretrained(identifier))
    end

    def self.from_file(path)
      new(InternalTokenizer.from_file(path))
    end

    def encode(text)
      raise TokenizerRuby::Error, "encode expects a String, got #{text.class}" unless text.is_a?(String)

      begin
        result = @inner._encode(text)
      rescue => e
        raise TokenizerRuby::Error, "failed to encode text: #{e.message}"
      end
      Encoding.new(
        ids: result[:ids],
        tokens: result[:tokens],
        offsets: result[:offsets],
        attention_mask: result[:attention_mask]
      )
    end

    def decode(ids)
      raise TokenizerRuby::Error, "decode expects an Array, got #{ids.class}" unless ids.is_a?(Array)

      begin
        @inner._decode(ids)
      rescue => e
        raise TokenizerRuby::Error, "failed to decode ids: #{e.message}"
      end
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
      raise TokenizerRuby::Error, "max_tokens must be positive, got #{max_tokens}" unless max_tokens > 0

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
  end
end
