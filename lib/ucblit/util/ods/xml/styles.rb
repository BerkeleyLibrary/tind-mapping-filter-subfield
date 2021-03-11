require 'nokogiri'
require 'ucblit/util/ods/xml/document_node'
require 'ucblit/util/ods/xml/office/document_styles'

module UCBLIT
  module Util
    module ODS
      module XML
        class Styles < DocumentNode
          def root_element_node
            document_styles
          end

          def document_styles
            @document_styles ||= Office::DocumentStyles.new(doc: doc)
          end
        end
      end
    end
  end
end
