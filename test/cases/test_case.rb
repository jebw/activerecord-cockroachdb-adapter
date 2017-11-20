require 'active_record/test_case'

module ActiveRecord
  class CockroachDBTestCase < TestCase
    def self.run(*args)
      super if current_adapter?(:CockroachDBAdapter)
    end
  end
end
