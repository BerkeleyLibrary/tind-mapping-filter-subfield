require 'marc_extensions'

require 'ucblit/util/arrays'

require 'ucblit/tind/export/column_group'
require 'ucblit/tind/export/column'
require 'ucblit/tind/export/export_exception'
require 'ucblit/tind/export/row'

require 'csv'
require 'stringio'

module UCBLIT
  module TIND
    module Export
      class Table
        include UCBLIT::Util::Arrays
        include UCBLIT::TIND::Config

        # ------------------------------------------------------------
        # Factory method

        class << self
          # Returns a new Table for the provided MARC records.
          #
          # @param records [Enumerable<MARC::Record>] the records
          # @param freeze [Boolean] whether to freeze the table
          # @return [Table] the table
          def from_records(records, freeze: false)
            table = records.each_with_object(Table.new) { |r, t| t << r }
            # noinspection RubyYardReturnMatch
            table.tap { |t| t.freeze if freeze }
          end
        end

        # ------------------------------------------------------------
        # Cell accessors

        def value_at(row, col)
          return unless (column = columns[col])

          column.value_at(row)
        end

        # ------------------------------------------------------------
        # Column accessors

        # The column headers
        #
        # @return [Array<String>] the column headers
        def headers
          columns.map(&:header)
        end

        # The columns
        #
        # @return [Array<Column>] the columns.
        def columns
          # NOTE: this isn't ||= because we only cache on #freeze
          @columns || all_column_groups.map(&:columns).flatten
        end

        def column_count
          columns.size
        end

        # ------------------------------------------------------------
        # Row / MARC::Record accessors

        def rows
          # NOTE: this isn't ||= because we only cache on #freeze
          @rows || each_row.to_a
        end

        # @yieldparam row [Row] each row
        def each_row
          return to_enum(:each_row) unless block_given?

          (0...row_count).each { |row| yield Row.new(columns, row) }
        end

        # The number of rows (records)
        #
        # @return [Integer] the number of rows
        def row_count
          marc_records.size
        end

        # The MARC records
        #
        # @return [Array<MARC::Record>] the records
        def marc_records
          @marc_records ||= []
        end

        # ------------------------------------------------------------
        # Modifiers

        # Adds the specified record
        #
        # @param marc_record [MARC::Record] the record to add
        def <<(marc_record)
          raise FrozenError, "can't modify frozen MARCTable" if frozen?

          logger.warn('MARC record is not frozen') unless marc_record.frozen?
          add_data_fields(marc_record, marc_records.size)
          marc_records << marc_record
          log_record_added(marc_record)

          self
        end

        # ------------------------------------------------------------
        # Object overrides

        def frozen?
          [marc_records, column_groups_by_tag].all?(&:frozen?) &&
            [@rows, @columns].all? { |d| !d.nil? && d.frozen? }
        end

        def freeze
          [marc_records, column_groups_by_tag].each(&:freeze)
          @columns ||= columns.freeze
          @rows ||= rows.freeze
          self
        end

        # ------------------------------------------------------------
        # Misc. instance methods

        def to_csv(out = nil)
          return write_csv(out) if out

          StringIO.new.tap { |io| write_csv(io) }.string
        end

        # ------------------------------------------------------------
        # Private methods

        private

        def log_record_added(marc_record)
          return logger.info("Added #{marc_record.record_id}: #{row_count} records total") if marc_record
        end

        def column_groups_by_tag
          @column_groups_by_tag ||= {}
        end

        def all_column_groups
          all_tags = column_groups_by_tag.keys.sort
          all_tags.each_with_object([]) do |tag, groups|
            tag_column_groups = column_groups_by_tag[tag]
            groups.concat(tag_column_groups)
          end
        end

        def add_data_fields(marc_record, row)
          marc_record.data_fields_by_tag.each do |tag, data_fields|
            tag_column_groups = (column_groups_by_tag[tag] ||= [])

            data_fields.inject(0) do |offset, df|
              1 + add_data_field(df, row, tag_column_groups, at_or_after: offset)
            end
          end
        rescue StandardError => e
          raise Export::ExportException, "Error adding MARC record #{marc_record.record_id} at row #{row}: #{e.message}"
        end

        def add_data_field(data_field, row, tag_column_groups, at_or_after: 0)
          added_at = find_index(in_array: tag_column_groups, start_index: at_or_after) { |cg| cg.maybe_add_at(row, data_field) }
          return added_at if added_at

          new_group = ColumnGroup.from_data_field(data_field, tag_column_groups.size).tap do |cg|
            raise Export::ExportException, "Unexpected failure to add #{data_field} to #{cg}" unless cg.maybe_add_at(row, data_field)
          end
          tag_column_groups << new_group
          tag_column_groups.size - 1
        end

        def write_csv(out)
          csv = out.respond_to?(:write) ? CSV.new(out) : CSV.open(out, 'wb')
          csv << headers
          each_row { |row| csv << row.values }
        end
      end
    end
  end
end
