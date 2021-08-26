#!/usr/bin/env ruby

# frozen_string_literal: true

require 'pathname'

require 'rubygems'
require 'bundler/setup'
require 'zip'

LIBRARY_NAME = 'hoard'

def main
  ensure_directory_exists('dist/lib')
  build "lib/#{LIBRARY_NAME}.rb", "dist/lib/#{LIBRARY_NAME}.rb"
  zip_output
end

def ensure_directory_exists(path)
  Pathname(path).mkpath
end

def build(input_filename, output_filename)
  input_content = File.read input_filename
  result_content = replace_require_statements_with_file_contents input_content
  File.write(output_filename, result_content)
end

def replace_require_statements_with_file_contents(string)
  result = string
  result = replace_require_statements(result) while require_statement? result
  result
end

def require_statement?(string)
  REQUIRE_STATEMENT =~ string
end

def replace_require_statements(string)
  string.gsub(REQUIRE_STATEMENT) do
    File.read Regexp.last_match[:filename]
  end
end

REQUIRE_STATEMENT = /^require '(?<filename>[^']+)'$/

def zip_output
  zip_file = Pathname("dist/#{LIBRARY_NAME}.zip")
  zip_file.delete if zip_file.exist?
  Zip::File.open(zip_file, Zip::File::CREATE) do |zipfile|
    zipfile.add "lib/#{LIBRARY_NAME}.rb", "dist/lib/#{LIBRARY_NAME}.rb"
    zipfile.add 'Smaug.toml', 'Smaug.toml'
  end
  Pathname('dist/lib').rmtree
end

main if __FILE__ == $PROGRAM_NAME
