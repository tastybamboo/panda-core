module Panda
  module Core
    class EnableHstore < ActiveRecord::Migration[8.0]
      def change
        enable_extension :hstore
      end
    end
  end
end
