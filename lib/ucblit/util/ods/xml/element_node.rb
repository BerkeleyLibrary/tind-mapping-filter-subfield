require 'nokogiri'
require 'ucblit/util/ods/xml/namespace'

module UCBLIT
  module Util
    module ODS
      module XML
        class ElementNode

          # @return [Nokogiri::XML::Document] the document containing this element
          attr_reader :doc

          # @return [Namespace] the namespace for this element
          attr_reader :namespace

          # @return [String] the name of this element
          attr_reader :name

          # @param namespace [String, Symbol, Namespace] the element namespace
          # @param name [String] the element name
          # @param doc [Nokogiri::XML::Document] the document containing this element
          def initialize(namespace, name, doc:)
            @namespace = ensure_namespace(namespace)
            @name = name
            @doc = doc
          end

          def prefix
            namespace.prefix
          end

          def element
            @element ||= create_element
          end

          # rubocop:disable Style/OptionalArguments
          def set_attribute(namespace = prefix, name, value)
            attr_name = prefixed_attr_name(namespace, name)
            attributes[attr_name] = value.to_s
          end
          # rubocop:enable Style/OptionalArguments

          # rubocop:disable Style/OptionalArguments
          def clear_attribute(namespace = prefix, name)
            attr_name = prefixed_attr_name(namespace, name)
            attributes.delete(attr_name)
          end
          # rubocop:enable Style/OptionalArguments

          def add_child(child)
            raise ArgumentError, "Not text or an element: #{child.inspect}" unless child.is_a?(ElementNode) || child.is_a?(String)

            child.tap { |c| children << c }
          end

          def empty?
            children.empty?
          end

          protected

          def prefixed_attr_name(ns, name)
            return "xmlns:#{name}" if ns.to_s == 'xmlns'

            "#{ensure_namespace(ns).prefix}:#{name}"
          end

          def attr_prefix(namespace)
            namespace.to_s == 'xmlns' ? namespace : ensure_namespace(namespace).prefix
          end

          def create_element
            doc.create_element("#{prefix}:#{name}", attributes).tap do |element|
              children.each do |child|
                next element.add_child(child.element) if child.is_a?(ElementNode)

                text_node = doc.create_text_node(child.to_s)
                element.add_child(text_node)
              end
            end
          end

          # @return [Hash<String, String>] the attributes, as a map from name to value
          def attributes
            # noinspection RubyYardReturnMatch
            @attributes ||= {}
          end

          # @return [Array<ElementNode>] the child elements
          def children
            @children ||= []
          end

          private

          def ensure_namespace(ns)
            return ns if ns.is_a?(Namespace)
            raise ArgumentError, "Not a recognized namespace: #{ns.inspect}" unless (ns_for_prefix = Namespace.for_prefix(ns.to_s.downcase))

            ns_for_prefix
          end
        end
      end
    end
  end
end
