require 'fileutils'
require 'pathname'

def warn_if_env_is_not_set
  return if ENV['DRAGONRUBY_PATH']

  puts 'Please set DRAGONRUBY_PATH environment variable with path to dragonruby executable'
  exit
end

def dragonruby_path
  Pathname.new(ENV['DRAGONRUBY_PATH']).realpath
end

warn_if_env_is_not_set

guard :shell do
  watch(/^[^#]*\.rb/) { |m|
    if run_all?(m)
      run_all
    else
      system "bundle exec reek #{m[0]}"
      system "bundle exec rubocop #{m[0]}"
      test_path = m[0].include?('tests/') ? Pathname.new(m[0]) : Pathname.new('tests') / m[0]
      next unless test_path.exist?

      `#{dragonruby_path} . --test #{test_path}`
    end
  }
end

def run_all
  system 'bundle exec reek app lib tests'
  system 'bundle exec rubocop app lib tests'
  `#{dragonruby_path} . --test tests/main.rb`
end

def run_all?(match)
  match.is_a? Array
end
