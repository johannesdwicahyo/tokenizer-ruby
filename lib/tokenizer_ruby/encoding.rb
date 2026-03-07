# frozen_string_literal: true

module TokenizerRuby
  class Encoding
    attr_reader :ids, :tokens, :offsets, :attention_mask

    def initialize(ids:, tokens:, offsets:, attention_mask:)
      @ids = ids
      @tokens = tokens
      @offsets = offsets
      @attention_mask = attention_mask
    end

    def length
      @ids.length
    end
  end
end
