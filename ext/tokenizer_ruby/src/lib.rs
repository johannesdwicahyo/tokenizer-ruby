use magnus::{
    define_module, function, method, prelude::*, Error, RHash, Ruby,
    RArray,
};
use std::sync::Mutex;
use tokenizers::Tokenizer;

#[magnus::wrap(class = "TokenizerRuby::InternalTokenizer", free_immediately)]
struct RubyTokenizer(Mutex<Tokenizer>);

fn from_pretrained(ruby: &Ruby, identifier: String) -> Result<RubyTokenizer, Error> {
    let tokenizer = Tokenizer::from_pretrained(&identifier, None)
        .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))?;
    Ok(RubyTokenizer(Mutex::new(tokenizer)))
}

fn from_file(ruby: &Ruby, path: String) -> Result<RubyTokenizer, Error> {
    let tokenizer = Tokenizer::from_file(&path)
        .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))?;
    Ok(RubyTokenizer(Mutex::new(tokenizer)))
}

fn encoding_to_hash(ruby: &Ruby, encoding: &tokenizers::Encoding) -> Result<RHash, Error> {
    let hash = RHash::new();

    let ids: Vec<i64> = encoding.get_ids().iter().map(|&id| id as i64).collect();
    hash.aset(ruby.sym_new("ids"), RArray::from_vec(ids))?;

    let tokens: Vec<String> = encoding.get_tokens().to_vec();
    hash.aset(ruby.sym_new("tokens"), RArray::from_vec(tokens))?;

    let offsets_array = RArray::new();
    for &(start, end_) in encoding.get_offsets() {
        offsets_array.push(RArray::from_vec(vec![start as i64, end_ as i64]))?;
    }
    hash.aset(ruby.sym_new("offsets"), offsets_array)?;

    let mask: Vec<i64> = encoding.get_attention_mask().iter().map(|&m| m as i64).collect();
    hash.aset(ruby.sym_new("attention_mask"), RArray::from_vec(mask))?;

    // type_ids
    let type_ids: Vec<i64> = encoding.get_type_ids().iter().map(|&t| t as i64).collect();
    hash.aset(ruby.sym_new("type_ids"), RArray::from_vec(type_ids))?;

    // special_tokens_mask
    let special_mask: Vec<i64> = encoding.get_special_tokens_mask().iter().map(|&m| m as i64).collect();
    hash.aset(ruby.sym_new("special_tokens_mask"), RArray::from_vec(special_mask))?;

    // word_ids
    let word_ids_array = RArray::new();
    for word_id in encoding.get_word_ids() {
        match word_id {
            Some(id) => word_ids_array.push(*id as i64)?,
            None => word_ids_array.push(ruby.qnil())?,
        }
    }
    hash.aset(ruby.sym_new("word_ids"), word_ids_array)?;

    Ok(hash)
}

impl RubyTokenizer {
    fn encode(ruby: &Ruby, rb_self: &Self, text: String, add_special_tokens: bool) -> Result<RHash, Error> {
        let guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        let encoding = guard
            .encode(text.as_str(), add_special_tokens)
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))?;
        encoding_to_hash(ruby, &encoding)
    }

    fn decode(ruby: &Ruby, rb_self: &Self, ids: Vec<u32>, skip_special_tokens: bool) -> Result<String, Error> {
        let guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        guard
            .decode(&ids, skip_special_tokens)
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))
    }

    fn encode_batch(ruby: &Ruby, rb_self: &Self, texts: Vec<String>, add_special_tokens: bool) -> Result<RArray, Error> {
        let inputs: Vec<&str> = texts.iter().map(|s| s.as_str()).collect();
        let guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        let encodings = guard
            .encode_batch(inputs, add_special_tokens)
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))?;
        let result = RArray::new();
        for encoding in &encodings {
            result.push(encoding_to_hash(ruby, encoding)?)?;
        }
        Ok(result)
    }

    fn decode_batch(ruby: &Ruby, rb_self: &Self, ids_array: Vec<Vec<u32>>, skip_special_tokens: bool) -> Result<Vec<String>, Error> {
        let refs: Vec<&[u32]> = ids_array.iter().map(|v| v.as_slice()).collect();
        let guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        guard
            .decode_batch(&refs, skip_special_tokens)
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))
    }

    fn vocab_size(ruby: &Ruby, rb_self: &Self) -> Result<usize, Error> {
        let guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        Ok(guard.get_vocab_size(true))
    }

    fn token_to_id(ruby: &Ruby, rb_self: &Self, token: String) -> Result<Option<u32>, Error> {
        let guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        Ok(guard.token_to_id(&token))
    }

    fn id_to_token(ruby: &Ruby, rb_self: &Self, id: u32) -> Result<Option<String>, Error> {
        let guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        Ok(guard.id_to_token(id))
    }

    fn enable_truncation(ruby: &Ruby, rb_self: &Self, max_length: usize) -> Result<(), Error> {
        let params = tokenizers::TruncationParams {
            max_length,
            ..Default::default()
        };
        let mut guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        let _ = guard.with_truncation(Some(params));
        Ok(())
    }

    fn disable_truncation(ruby: &Ruby, rb_self: &Self) -> Result<(), Error> {
        let mut guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        let _ = guard.with_truncation(None);
        Ok(())
    }

    fn enable_padding(ruby: &Ruby, rb_self: &Self, length: usize, pad_token: String) -> Result<(), Error> {
        let params = tokenizers::PaddingParams {
            strategy: tokenizers::PaddingStrategy::Fixed(length),
            pad_token,
            ..Default::default()
        };
        let mut guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        guard.with_padding(Some(params));
        Ok(())
    }

    fn disable_padding(ruby: &Ruby, rb_self: &Self) -> Result<(), Error> {
        let mut guard = rb_self.0.lock()
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("lock poisoned: {}", e)))?;
        guard.with_padding(None);
        Ok(())
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = define_module("TokenizerRuby")?;

    let class = module.define_class("InternalTokenizer", ruby.class_object())?;
    class.define_singleton_method("from_pretrained", function!(from_pretrained, 1))?;
    class.define_singleton_method("from_file", function!(from_file, 1))?;
    class.define_method("_encode", method!(RubyTokenizer::encode, 2))?;
    class.define_method("_decode", method!(RubyTokenizer::decode, 2))?;
    class.define_method("_encode_batch", method!(RubyTokenizer::encode_batch, 2))?;
    class.define_method("_decode_batch", method!(RubyTokenizer::decode_batch, 2))?;
    class.define_method("vocab_size", method!(RubyTokenizer::vocab_size, 0))?;
    class.define_method("token_to_id", method!(RubyTokenizer::token_to_id, 1))?;
    class.define_method("id_to_token", method!(RubyTokenizer::id_to_token, 1))?;
    class.define_method("_enable_truncation", method!(RubyTokenizer::enable_truncation, 1))?;
    class.define_method("_disable_truncation", method!(RubyTokenizer::disable_truncation, 0))?;
    class.define_method("_enable_padding", method!(RubyTokenizer::enable_padding, 2))?;
    class.define_method("_disable_padding", method!(RubyTokenizer::disable_padding, 0))?;

    Ok(())
}
