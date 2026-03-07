# tokenizer-ruby

Ruby bindings for [HuggingFace Tokenizers](https://github.com/huggingface/tokenizers). Fast, Rust-powered tokenization for any HuggingFace model — GPT-2, BERT, LLaMA, Claude, and more.

## Installation

```
gem install tokenizer-ruby
```

Or add to your Gemfile:

```ruby
gem "tokenizer-ruby"
```

**Note:** Requires Rust toolchain for compilation. Install via [rustup](https://rustup.rs/).

## Usage

### Load a tokenizer

```ruby
require "tokenizer_ruby"

# From HuggingFace Hub
tokenizer = TokenizerRuby::Tokenizer.from_pretrained("gpt2")
tokenizer = TokenizerRuby::Tokenizer.from_pretrained("bert-base-uncased")

# From a local file
tokenizer = TokenizerRuby::Tokenizer.from_file("/path/to/tokenizer.json")
```

### Encode and decode

```ruby
encoding = tokenizer.encode("Hello, world!")
encoding.ids           # => [15496, 11, 995, 0]
encoding.tokens        # => ["Hello", ",", " world", "!"]
encoding.offsets       # => [[0, 5], [5, 6], [6, 12], [12, 13]]
encoding.attention_mask # => [1, 1, 1, 1]
encoding.length        # => 4

tokenizer.decode([15496, 11, 995, 0])  # => "Hello, world!"
```

### Batch processing

```ruby
encodings = tokenizer.encode_batch(["Hello", "World"])
decoded = tokenizer.decode_batch(encodings.map(&:ids))
# => ["Hello", "World"]
```

### Token counting

```ruby
tokenizer.count("Hello, world!")  # => 4
```

### Truncation

```ruby
# Truncate text to a token limit
tokenizer.truncate("This is a long sentence...", max_tokens: 5)

# Enable automatic truncation on all encodes
tokenizer.enable_truncation(max_length: 512)
```

### Padding

```ruby
tokenizer.enable_padding(length: 128, pad_token: "[PAD]")
encoding = tokenizer.encode("Hello")
encoding.ids.length        # => 128
encoding.attention_mask     # => [1, 0, 0, 0, ...]
```

### Vocabulary

```ruby
tokenizer.vocab_size           # => 50257
tokenizer.token_to_id("hello") # => 31373
tokenizer.id_to_token(31373)   # => "hello"
```

## Requirements

- Ruby >= 3.1
- Rust toolchain (for building from source)

## Development

```
bundle install
bundle exec rake compile
bundle exec rake test
```

## License

MIT

## Author

Johannes Dwi Cahyo — [@johannesdwicahyo](https://github.com/johannesdwicahyo)
