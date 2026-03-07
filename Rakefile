# frozen_string_literal: true

require "rake/testtask"
require "rb_sys/extensiontask"

GEMSPEC = Gem::Specification.load("tokenizer-ruby.gemspec")

RbSys::ExtensionTask.new("tokenizer_ruby", GEMSPEC) do |ext|
  ext.lib_dir = "lib/tokenizer_ruby"
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

task default: [:compile, :test]
