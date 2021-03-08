require 'marc_extensions'

module UCBLIT
  module TIND
    module Export
      class Column
        attr_reader :col_in_group
        attr_reader :column_group

        # Initializes a new column
        #
        # @param column_group [ColumnGroup] the group containing this column
        # @param col_in_group [Integer] the index of this column in the group
        def initialize(column_group, col_in_group)
          @column_group = column_group
          @col_in_group = col_in_group
        end

        def header
          # NOTE: that TIND "-#" suffixes must be unique by tag, not tag + ind1 + ind2
          @header ||= "#{column_group.prefix}#{subfield_code}-#{1 + column_group.index_in_tag}"
        end

        def subfield_code
          @subfield_code ||= column_group.subfield_codes[col_in_group]
        end

        def value_at(row)
          column_group.value_at(row, col_in_group)
        end

        def can_edit?
          @can_edit ||= Filter.can_edit?(
            column_group.tag,
            column_group.ind1,
            column_group.ind2,
            subfield_code
          )
        end

        def width_chars
          @width_chars = nil unless column_group.frozen?
          @width_chars ||= begin
            w_header = header.size
            (0...column_group.row_count).inject(w_header) do |w_max, row|
              w_row = value_at(row).to_s.size
              [w_max, w_row].max
            end
          end
        end

      end
    end
  end
end
