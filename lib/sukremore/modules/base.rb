# Main abstract class for all module specific classes.
module Sukremore
  module Modules
    class Base
      include Sukremore
      def initialize client
        @client= client
      end
    end
  end
end
