#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/tokenizer_ruby"

puts "=" * 60
puts "tokenizer-ruby: Real-World Usage Examples"
puts "=" * 60

# -----------------------------------------------------------
# 1. Load different model tokenizers
# -----------------------------------------------------------
puts "\n1. Loading tokenizers from HuggingFace Hub"
puts "-" * 40

gpt2 = TokenizerRuby::Tokenizer.from_pretrained("gpt2")
puts "   GPT-2 vocab size: #{gpt2.vocab_size}"

bert = TokenizerRuby::Tokenizer.from_pretrained("bert-base-uncased")
puts "   BERT vocab size: #{bert.vocab_size}"

# -----------------------------------------------------------
# 2. Token counting for LLM API calls
#    (most common real-world use case)
# -----------------------------------------------------------
puts "\n2. Token Counting (LLM cost estimation)"
puts "-" * 40

prompt = <<~TEXT
  You are a helpful assistant. Analyze the following customer review
  and extract the sentiment, key topics, and suggested improvements.

  Review: "I've been using this product for 3 months now and I'm mostly
  satisfied. The build quality is excellent and it works as advertised.
  However, the mobile app is buggy and the customer support response time
  could be better. Overall, I'd recommend it with some reservations."
TEXT

token_count = gpt2.count(prompt)
cost_per_1k = 0.002 # hypothetical $/1K tokens
estimated_cost = (token_count / 1000.0) * cost_per_1k

puts "   Prompt: #{prompt.lines.first.strip}..."
puts "   Token count: #{token_count}"
puts "   Estimated cost: $#{'%.6f' % estimated_cost}"

# -----------------------------------------------------------
# 3. Truncating text to fit context windows
# -----------------------------------------------------------
puts "\n3. Context Window Truncation"
puts "-" * 40

long_text = "The quick brown fox jumps over the lazy dog. " * 50
puts "   Original length: #{gpt2.count(long_text)} tokens"

truncated = gpt2.truncate(long_text, max_tokens: 20)
puts "   Truncated to 20 tokens: #{gpt2.count(truncated)} tokens"
puts "   Preview: #{truncated[0..60]}..."

# -----------------------------------------------------------
# 4. Comparing tokenization across models
# -----------------------------------------------------------
puts "\n4. Tokenization Comparison (GPT-2 vs BERT)"
puts "-" * 40

samples = [
  "Hello, world!",
  "tokenizer-ruby is awesome",
  "Machine learning is transforming industries",
  "こんにちは世界",
  "user@example.com",
]

puts "   %-40s %8s %8s" % ["Text", "GPT-2", "BERT"]
puts "   " + "-" * 56
samples.each do |text|
  gpt2_count = gpt2.count(text)
  bert_count = bert.count(text)
  label = text.length > 35 ? text[0..32] + "..." : text
  puts "   %-40s %8d %8d" % [label, gpt2_count, bert_count]
end

# -----------------------------------------------------------
# 5. Batch processing (e.g., preprocessing a dataset)
# -----------------------------------------------------------
puts "\n5. Batch Encoding (dataset preprocessing)"
puts "-" * 40

reviews = [
  "Great product, highly recommend!",
  "Terrible experience, want a refund.",
  "It's okay, nothing special.",
  "Best purchase I've ever made!",
  "Wouldn't buy again, poor quality.",
]

encodings = gpt2.encode_batch(reviews)
encodings.each_with_index do |enc, i|
  puts "   [#{enc.length} tokens] #{reviews[i]}"
end

# decode them back
decoded = gpt2.decode_batch(encodings.map(&:ids))
puts "\n   Round-trip check: #{decoded == reviews ? 'PASS' : 'FAIL'}"

# -----------------------------------------------------------
# 6. Token-level analysis
# -----------------------------------------------------------
puts "\n6. Token-Level Analysis"
puts "-" * 40

text = "Tokenization helps language models understand text."
encoding = gpt2.encode(text)

puts "   Text: #{text}"
puts "   Tokens:"
encoding.tokens.each_with_index do |token, i|
  offset = encoding.offsets[i]
  original = text[offset[0]...offset[1]]
  puts "     #{'%3d' % encoding.ids[i]} | %-15s | offset [%2d, %2d] | original: %s" % [
    token, offset[0], offset[1], original.inspect
  ]
end

# -----------------------------------------------------------
# 7. Vocab lookups (special tokens, subwords)
# -----------------------------------------------------------
puts "\n7. Vocabulary Lookups"
puts "-" * 40

words = ["hello", "world", "the", "AI", "Ruby"]
words.each do |word|
  id = gpt2.token_to_id(word)
  if id
    roundtrip = gpt2.id_to_token(id)
    puts "   '#{word}' -> id #{id} -> '#{roundtrip}'"
  else
    puts "   '#{word}' -> not in vocabulary (would be subword-tokenized)"
  end
end

# -----------------------------------------------------------
# 8. Padding for batch inference
# -----------------------------------------------------------
puts "\n8. Padding for Batch Inference"
puts "-" * 40

padded_tokenizer = TokenizerRuby::Tokenizer.from_pretrained("bert-base-uncased")
padded_tokenizer.enable_padding(length: 10, pad_token: "[PAD]")

sentences = ["Hello!", "How are you doing today?"]
sentences.each do |s|
  enc = padded_tokenizer.encode(s)
  puts "   %-30s ids: %-40s mask: %s" % [
    s, enc.ids.inspect, enc.attention_mask.inspect
  ]
end

puts "\n" + "=" * 60
puts "All examples completed successfully!"
puts "=" * 60
