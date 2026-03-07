# frozen_string_literal: true

require_relative "lib/tokenizer_ruby/version"

Gem::Specification.new do |spec|
  spec.name = "tokenizer-ruby"
  spec.version = TokenizerRuby::VERSION
  spec.authors = ["Johannes Dwi Cahyo"]
  spec.homepage = "https://github.com/johannesdwicahyo/tokenizer-ruby"
  spec.summary = "Ruby bindings for HuggingFace tokenizers"
  spec.description = "Fast tokenization for Ruby using HuggingFace's Rust-powered tokenizers library. " \
                     "Supports GPT, BERT, LLaMA, Claude, and any HuggingFace tokenizer."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.files = Dir[
    "lib/**/*.rb",
    "ext/**/*.{rs,toml,rb}",
    "LICENSE",
    "README.md",
    "CLAUDE.md"
  ]
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/tokenizer_ruby/extconf.rb"]

  spec.add_dependency "rb_sys", "~> 0.9"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
end
