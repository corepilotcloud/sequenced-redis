require "bundler/setup"
Bundler.require(:default)

require "minitest/autorun"
require "active_record"

adapter = ENV["ADAPTER"]&.to_sym || :postgresql
puts "Using #{adapter}"

database_yml = File.expand_path("support/database.yml", __dir__)
ActiveRecord::Base.configurations = YAML.load_file(database_yml)
begin
  ActiveRecord::Base.establish_connection(adapter)
  ActiveRecord::Base.connection.execute("SELECT 1")
rescue ActiveRecord::NoDatabaseError
  puts "Creating database"
  config = ActiveRecord::Base.configurations.configs_for(env_name: adapter.to_s, name: "primary").configuration_hash
  ActiveRecord::Tasks::DatabaseTasks.create(config)
end

require_relative "support/schema"
require_relative "support/models"
