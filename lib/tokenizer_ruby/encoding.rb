# frozen_string_literal: true

module TokenizerRuby
  class Encoding
    attr_reader :ids, :tokens, :offsets, :attention_mask,
                :type_ids, :special_tokens_mask, :word_ids

    def initialize(ids:, tokens:, offsets:, attention_mask:, type_ids: nil, special_tokens_mask: nil, word_ids: nil)
      @ids = ids
      @tokens = tokens
      @offsets = offsets
      @attention_mask = attention_mask
      @type_ids = type_ids
      @special_tokens_mask = special_tokens_mask
      @word_ids = word_ids
    end

    def length
      @ids.length
    end
  end
end
