# frozen_string_literal: true

require_relative "tokenizer_ruby/version"
require_relative "tokenizer_ruby/encoding"
require_relative "tokenizer_ruby/tokenizer"

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "tokenizer_ruby/#{$1}/tokenizer_ruby"
rescue LoadError
  require "tokenizer_ruby/tokenizer_ruby"
end

module TokenizerRuby
  class Error < StandardError; end
end
