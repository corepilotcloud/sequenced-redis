source "https://rubygems.org"

# Declare your gem's dependencies in sequenced.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

gem "appraisal"
gem "standardrb"

group :development, :test do
  # gem "mysql2"
  gem "net-imap"
  gem "net-pop"
  gem "net-smtp"
  gem "pg"
  gem "sqlite3", "~> 2.6"
  if defined?(@ar_gem_requirement)
    gem "activerecord", @ar_gem_requirement
    gem "railties", @ar_gem_requirement
  else
    gem "activerecord" # latest
  end
end

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use debugger
# gem 'ruby-debug19', :require => 'ruby-debug'
