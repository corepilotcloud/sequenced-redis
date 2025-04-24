require "redis"
module Sequenced
  class Generator
    attr_reader :record, :scope, :column, :start_at, :skip, :redis_client
    class_attribute :default_redis_client

    def self._default_redis_client
      Redis.new(
        url: ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" },
        ssl_params: {
          verify_mode: OpenSSL::SSL::VERIFY_NONE
        }
      )
    end

    self.default_redis_client ||= _default_redis_client

    def initialize(record, options = {})
      @record = record
      @scope = options[:scope]
      @column = options[:column].to_sym
      @start_at = options[:start_at]
      @skip = options[:skip]
      @redis_client = options[:redis_client] ||
        Sequenced::Generator.default_redis_client ||
        Sequenced::Generator._default_redis_client
    end

    def set
      return if skip? || id_set?

      record.send(:"#{column}=", next_id)
    end

    def id_set?
      !record.send(column).nil?
    end

    def skip?
      skip&.call(record)
    end

    def next_id(increment: true)
      prepare_next_id

      next_id_in_sequence(increment: increment)
    end

    def sequence_key
      "sequenced:#{record.class.base_class}:#{column}:#{scope_to_key(*scope)}"
    end

    # private

    def prepare_next_id
      if redis_client.exists?(sequence_key)
        return
      end

      lock_table

      start_at = self.start_at.respond_to?(:call) ? self.start_at.call(record) : self.start_at
      last_id = find_last_record&.send(column) || 0

      redis_client.set(sequence_key, max(last_id, start_at - 1), nx: true, ex: 86400)
    end

    def next_id_in_sequence(increment:)
      redis_client.call(increment ? "incr" : "get", sequence_key)
    end

    def scope_to_key(*columns)
      return unless columns.present?

      columns.collect { |c| "#{c}:#{record.send(c.to_sym)}" }.join(":")
    end

    def lock_table
      if postgresql?
        record.class.connection.execute("LOCK TABLE #{record.class.table_name} IN EXCLUSIVE MODE")
      end
    end

    def postgresql?
      defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) &&
        record.class.connection.is_a?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    end

    def base_relation
      record.class.base_class.unscoped
    end

    def find_last_record
      build_scope(*scope) do
        base_relation
          .where("#{column} IS NOT NULL")
          .order("#{column} DESC")
      end.first
    end

    def build_scope(*columns)
      rel = yield
      columns.each { |c| rel = rel.where(c => record.send(c.to_sym)) }
      rel
    end

    def max(*values)
      values.to_a.max
    end
  end
end
