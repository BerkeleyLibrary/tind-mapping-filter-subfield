require 'ucblit/util/ods/xml/table/repeatable'
require 'ucblit/util/ods/xml/text/p'

module UCBLIT
  module Util
    module ODS
      module XML
        module Table
          class TableCell < Repeatable
            attr_reader :cell_style

            def initialize(value = nil, cell_style = nil, number_repeated = 1, table:)
              super('table-cell', 'number-columns-repeated', number_repeated, table: table)

              @cell_style = cell_style

              set_attribute('style-name', cell_style.name) if cell_style
              @children = [XML::Text::P.new(value)] if value
            end
          end
        end
      end
    end
  end

end
