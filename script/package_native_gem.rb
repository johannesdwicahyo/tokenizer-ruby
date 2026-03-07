#!/usr/bin/env ruby
# frozen_string_literal: true

# Package native gems for the current platform.
# Usage: ruby script/package_native_gem.rb

require "fileutils"

platform = Gem::Platform.local.to_s
puts "Packaging native gem for #{platform}..."

system("bundle exec rake compile") || abort("Compilation failed")

# Find the compiled .bundle/.so
lib_dir = File.expand_path("../lib/tokenizer_ruby", __dir__)
native_files = Dir["#{lib_dir}/**/*.{bundle,so,dylib}"]

if native_files.empty?
  abort("No compiled native extension found in #{lib_dir}")
end

puts "Found native extensions:"
native_files.each { |f| puts "  #{f}" }

system("gem build tokenizer-ruby.gemspec") || abort("gem build failed")

puts "Done! Native gem packaged for #{platform}"
