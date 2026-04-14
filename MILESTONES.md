# tokenizer-ruby — Milestones

> **Source of truth:** https://github.com/johannesdwicahyo/tokenizer-ruby/milestones
> **Last synced:** 2026-04-14

This file mirrors the GitHub milestones for this repo. Edit the milestone or issues on GitHub and re-sync, do not hand-edit.

## v1.0.0 — Stable Release (**open**)

_Frozen public API, YARD documentation, graceful network error handling, auth token for gated models, offline mode, improved inspect/to_s, full test matrix (Ruby 3.1–3.4, Linux + macOS), memory leak and fuzz testing._

- [ ] #19 Add YARD documentation
- [ ] #20 Graceful network error handling in from_pretrained
- [ ] #21 Add inspect/to_s and freeze public API
- [ ] #22 Full test matrix, memory leak and fuzz testing

## v0.5.0 — Performance & Advanced Features (**open**)

_Sentence-pair encoding, vocabulary extension, tokenizer serialization, streaming encoding for large texts, Rayon-based batch parallelism, optimized token counting, benchmarks vs tiktoken_ruby and Python tokenizers._

- [ ] #15 Add encode_pair for sentence-pair tasks
- [ ] #16 Add add_special_tokens / add_tokens to extend vocabulary
- [ ] #17 Add save(path) to serialize tokenizer
- [ ] #18 Optimize batch parallelism and token counting

## v0.4.0 — Rails Integration (**open**)

_Global default tokenizer config, ActiveModel token_length validator, Railtie auto-configuration, tokenizer file caching with XDG_CACHE_HOME support, from_pretrained cache_dir option._

- [ ] #12 Add global default tokenizer config
- [ ] #13 Add ActiveModel token_length validator
- [ ] #14 Add Railtie and tokenizer file caching

## v0.3.0 — Precompiled Binaries (**open**)

_GitHub Actions CI (Ruby 3.1–3.4), cross-compilation via rake-compiler-dock for x86_64-linux, aarch64-linux, x86_64-darwin, arm64-darwin. Precompiled native gems so users skip Rust toolchain. Auto-release on tag push. Fix gemspec to exclude CLAUDE.md._

- [ ] #8 Add GitHub Actions CI workflow
- [ ] #9 Cross-compile precompiled native gems
- [ ] #10 Auto-release workflow on git tag push
- [ ] #11 Exclude CLAUDE.md from gemspec and add Cargo.lock

## v0.2.0 — Robustness & Thread Safety (**closed**)

_Thread-safe tokenizer (Mutex/RwLock), proper error classes, configurable special tokens, additional Encoding fields (type_ids, special_tokens_mask, word_ids), disable truncation/padding, and expanded test coverage (BERT, LLaMA, concurrency, edge cases)._

- [x] #1 Replace RefCell with Mutex/RwLock for thread safety
- [x] #2 Add TokenizerRuby::Error subclass
- [x] #3 Add add_special_tokens parameter to encode
- [x] #4 Add skip_special_tokens parameter to decode
- [x] #5 Add disable_truncation and disable_padding
- [x] #6 Add Encoding#type_ids, #special_tokens_mask, #word_ids
- [x] #7 Add thread safety, BERT, LLaMA, and edge case tests
