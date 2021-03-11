require 'ucblit/util/ods/xml/style/style'
require 'ucblit/util/ods/xml/style/table_cell_properties'
require 'ucblit/util/ods/xml/style/text_properties'

module UCBLIT
  module Util
    module ODS
      module XML
        module Style
          class CellStyle < Style

            attr_reader :color

            # Initializes a new cell style. Note that this should not be called
            # directly, but only from {XML::Office::AutomaticStyles#add_cell_style}.
            #
            # @param styles [XML::Office::AutomaticStyles] the document styles
            # rubocop:disable Style/OptionalBooleanParameter
            def initialize(name, protected = false, color = nil, styles:)
              super(name, :table_cell, doc: styles.doc)
              @protected = protected
              @color = color

              set_attribute('parent-style-name', 'Default')
              add_default_children!
            end
            # rubocop:enable Style/OptionalBooleanParameter

            def protected?
              @protected
            end

            private

            def add_default_children!
              children << TableCellProperties.new(protected?, doc: doc)
              children << TextProperties.new(color: color, doc: doc) if color
            end
          end
        end
      end
    end
  end
end
