# Milestones for tokenizer-ruby

## v0.1.0 — Core MVP (DONE)
- [x] `from_pretrained` / `from_file`
- [x] `encode` / `decode`
- [x] `encode_batch` / `decode_batch`
- [x] `vocab_size`, `token_to_id`, `id_to_token`
- [x] `count`, `truncate`
- [x] `enable_truncation`, `enable_padding`
- [x] 18 tests passing
- [x] Published to RubyGems + gem.coop

---

## v0.2.0 — Robustness & Thread Safety

### Fix
- `RefCell` is not thread-safe — replace with `Mutex` or `RwLock` so concurrent threads can encode safely
- Add `TokenizerRuby::Error` subclass instead of raising generic `RuntimeError`
- `encode` with `add_special_tokens` parameter (currently hardcoded to `false`)
- `decode` with `skip_special_tokens` parameter (currently hardcoded to `true`)

### Add
- `disable_truncation` / `disable_padding` (no way to undo currently)
- `Encoding#type_ids` (token type IDs, needed for BERT-style models)
- `Encoding#special_tokens_mask`
- `Encoding#word_ids` (word-level mapping)

### Test
- Thread safety test with concurrent encoding
- Test with BERT tokenizer (special tokens `[CLS]`, `[SEP]`)
- Test with LLaMA tokenizer
- Edge cases: very long text, special characters, null bytes

---

## v0.3.0 — Precompiled Binaries

### Add
- GitHub Actions CI workflow (test on Ruby 3.1–3.4)
- Cross-compilation via `rake-compiler-dock` for:
  - `x86_64-linux`, `aarch64-linux`
  - `x86_64-darwin`, `arm64-darwin`
- Precompiled native gems so users skip Rust toolchain
- Auto-release workflow on git tag push

### Fix
- Gemspec `files` should exclude `CLAUDE.md` (contains API keys)
- Add `Cargo.lock` to gem for reproducible builds

---

## v0.4.0 — Rails Integration

### Add
- `TokenizerRuby.default_tokenizer = "gpt2"` global config
- `TokenizerRuby.default_tokenizer` returns a cached instance
- ActiveModel validator:
  ```ruby
  validates :content, token_length: { maximum: 4096 }
  validates :content, token_length: { minimum: 10, tokenizer: "bert-base-uncased" }
  ```
- `TokenizerRuby::Railtie` for auto-configuration
- Caching of downloaded tokenizer files (respect `XDG_CACHE_HOME`)
- `from_pretrained` with `cache_dir:` option

---

## v0.5.0 — Performance & Advanced Features

### Add
- `encode_pair(text_a, text_b)` for sentence-pair tasks (BERT NLI, etc.)
- `add_special_tokens` / `add_tokens` to extend vocabulary
- `save(path)` to serialize tokenizer to file
- Streaming/chunked encoding for very large texts
- Benchmarks vs tiktoken_ruby and Python tokenizers

### Optimize
- Batch encoding parallelism (use Rayon in Rust for multi-core)
- Reduce Ruby<->Rust boundary crossings in `count` (avoid full encoding when only IDs needed)

---

## v1.0.0 — Stable Release

### Fix
- Freeze public API
- Full YARD documentation
- Comprehensive error messages with actionable hints
- Handle network errors gracefully in `from_pretrained` (timeout, retry, offline mode)

### Add
- `from_pretrained` with auth token for gated models (LLaMA, etc.)
- Offline mode: `TokenizerRuby::Tokenizer.from_pretrained("gpt2", offline: true)`
- `#inspect` / `#to_s` on Tokenizer and Encoding for better debugging

### Test
- Full test matrix: Ruby 3.1–3.4, Linux + macOS
- Memory leak testing
- Fuzz testing with random Unicode input
