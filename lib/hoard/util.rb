module Hoard
  # General utility functions
  module Util
    class << self
      def call_according_to_arity(callable, *args)
        passed_args = args[0...callable.arity]
        callable.call(*passed_args)
      end
    end
  end
end
