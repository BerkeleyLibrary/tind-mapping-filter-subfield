require 'ucblit/util/ods/xml/element_node'
require 'ucblit/util/ods/xml/style/family'

module UCBLIT
  module Util
    module ODS
      module XML
        module Style
          class Style < XML::ElementNode

            attr_reader :name, :family

            def initialize(name, family, doc:)
              super(:style, 'style', doc: doc)

              @name = name
              @family = Family.ensure_family(family)

              set_default_attributes!
            end

            private

            def set_default_attributes!
              set_attribute('name', name)
              set_attribute('family', family)
            end
          end
        end
      end
    end
  end
end
