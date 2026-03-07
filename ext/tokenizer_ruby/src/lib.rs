use magnus::{
    define_module, function, method, prelude::*, Error, RHash, Ruby,
    RArray,
};
use std::cell::RefCell;
use tokenizers::Tokenizer;

#[magnus::wrap(class = "TokenizerRuby::InternalTokenizer", free_immediately)]
struct RubyTokenizer(RefCell<Tokenizer>);

fn from_pretrained(ruby: &Ruby, identifier: String) -> Result<RubyTokenizer, Error> {
    let tokenizer = Tokenizer::from_pretrained(&identifier, None)
        .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))?;
    Ok(RubyTokenizer(RefCell::new(tokenizer)))
}

fn from_file(ruby: &Ruby, path: String) -> Result<RubyTokenizer, Error> {
    let tokenizer = Tokenizer::from_file(&path)
        .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))?;
    Ok(RubyTokenizer(RefCell::new(tokenizer)))
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

    Ok(hash)
}

impl RubyTokenizer {
    fn encode(ruby: &Ruby, rb_self: &Self, text: String) -> Result<RHash, Error> {
        let encoding = rb_self.0.borrow()
            .encode(text.as_str(), false)
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))?;
        encoding_to_hash(ruby, &encoding)
    }

    fn decode(ruby: &Ruby, rb_self: &Self, ids: Vec<u32>) -> Result<String, Error> {
        rb_self.0.borrow()
            .decode(&ids, true)
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))
    }

    fn encode_batch(ruby: &Ruby, rb_self: &Self, texts: Vec<String>) -> Result<RArray, Error> {
        let inputs: Vec<&str> = texts.iter().map(|s| s.as_str()).collect();
        let encodings = rb_self.0.borrow()
            .encode_batch(inputs, false)
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))?;
        let result = RArray::new();
        for encoding in &encodings {
            result.push(encoding_to_hash(ruby, encoding)?)?;
        }
        Ok(result)
    }

    fn decode_batch(ruby: &Ruby, rb_self: &Self, ids_array: Vec<Vec<u32>>) -> Result<Vec<String>, Error> {
        let refs: Vec<&[u32]> = ids_array.iter().map(|v| v.as_slice()).collect();
        rb_self.0.borrow()
            .decode_batch(&refs, true)
            .map_err(|e| Error::new(ruby.exception_runtime_error(), format!("{}", e)))
    }

    fn vocab_size(&self) -> usize {
        self.0.borrow().get_vocab_size(true)
    }

    fn token_to_id(&self, token: String) -> Option<u32> {
        self.0.borrow().token_to_id(&token)
    }

    fn id_to_token(&self, id: u32) -> Option<String> {
        self.0.borrow().id_to_token(id)
    }

    fn enable_truncation(&self, max_length: usize) {
        let params = tokenizers::TruncationParams {
            max_length,
            ..Default::default()
        };
        let _ = self.0.borrow_mut().with_truncation(Some(params));
    }

    fn enable_padding(&self, length: usize, pad_token: String) {
        let params = tokenizers::PaddingParams {
            strategy: tokenizers::PaddingStrategy::Fixed(length),
            pad_token,
            ..Default::default()
        };
        self.0.borrow_mut().with_padding(Some(params));
    }
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = define_module("TokenizerRuby")?;

    let class = module.define_class("InternalTokenizer", ruby.class_object())?;
    class.define_singleton_method("from_pretrained", function!(from_pretrained, 1))?;
    class.define_singleton_method("from_file", function!(from_file, 1))?;
    class.define_method("_encode", method!(RubyTokenizer::encode, 1))?;
    class.define_method("_decode", method!(RubyTokenizer::decode, 1))?;
    class.define_method("_encode_batch", method!(RubyTokenizer::encode_batch, 1))?;
    class.define_method("_decode_batch", method!(RubyTokenizer::decode_batch, 1))?;
    class.define_method("vocab_size", method!(RubyTokenizer::vocab_size, 0))?;
    class.define_method("token_to_id", method!(RubyTokenizer::token_to_id, 1))?;
    class.define_method("id_to_token", method!(RubyTokenizer::id_to_token, 1))?;
    class.define_method("_enable_truncation", method!(RubyTokenizer::enable_truncation, 1))?;
    class.define_method("_enable_padding", method!(RubyTokenizer::enable_padding, 2))?;

    Ok(())
}
