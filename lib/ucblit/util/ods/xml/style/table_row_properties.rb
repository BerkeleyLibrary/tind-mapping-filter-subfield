require 'ucblit/util/ods/xml/element_node'

module UCBLIT
  module Util
    module ODS
      module XML
        module Style
          class TableColumnProperties < ElementNode
            attr_reader :width

            def initialize(width, doc:)
              super(:table, 'table-column-properties', doc: doc)
              @width = width
              set_default_attributes!
            end

            private

            def set_default_attributes!
              set_attribute(:fo, 'break-before', 'auto')
              set_attribute('column-width', width)
            end
          end
        end
      end
    end
  end
end
