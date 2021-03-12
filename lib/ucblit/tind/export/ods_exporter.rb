require 'ucblit/util/arrays'
require 'ucblit/tind/export/exporter_base'
require 'ucblit/tind/export/table_metrics'
require 'ucblit/util/ods/spreadsheet'

module UCBLIT
  module TIND
    module Export
      # Exporter for OpenOffice/LibreOffice format
      class ODSExporter < ExporterBase

        LOCKED_CELL_COLOR = '#c0362c'.freeze

        # Round column widths up to nearest quarter inch
        EIGHTH = '1/8'.to_r

        # Max column width before wrapping
        MAX_COLUMN_WIDTH_INCHES = 3.0

        # Exports {ExportBase#collection} as an OpenOffice/LibreOffice spreadsheet
        # @overload export
        #   Exports to a new string.
        #   @return [String] a binary string containing the spreadsheet data.
        # @overload export(out)
        #   Exports to the specified output stream.
        #   @param out [IO] the output stream
        #   @return[void]
        # @overload export(path)
        #   Exports to the specified file. If `path` denotes a directory, the
        #   spreadsheet will be written as exploded, pretty-printed XML.
        #   @param path [String, Pathname] the path to the output file or directory
        #   @return[void]
        #   @see UCBLIT::Util::ODS::Spreadsheet#write_exploded_to
        def export(out = nil)
          populate_spreadsheet!
          spreadsheet.write_to(out)
        end

        # ------------------------------------------------------------
        # Private methods

        private

        # ------------------------------
        # Private accessors

        def spreadsheet
          @spreadsheet ||= UCBLIT::Util::ODS::Spreadsheet.new
        end

        def table
          @table ||= spreadsheet.add_table(collection)
        end

        def table_metrics
          @table_metrics ||= TableMetrics.new(export_table)
        end

        # @return [UCBLIT::Util::ODS::XML::Office::AutomaticStyles] the styles
        def styles
          spreadsheet.auto_styles
        end

        def header_cell_style_for(col_index)
          @header_cell_styles ||= []
          @header_cell_styles[col_index] ||= begin
            protected = protected?(col_index)
            find_or_create_cell_style(
              protected,
              color: (protected ? LOCKED_CELL_COLOR : nil),
              font_weight: 'bold'
            )
          end
        end

        def find_or_create_cell_style(protected, color: nil, font_weight: nil, wrap: false)
          # TODO: move lookup/caching behind AutomaticStyles#find_or_create_cell_style
          color ||= LOCKED_CELL_COLOR if protected
          cell_styles = (@cell_styles ||= {})
          style_key = [protected, color, font_weight, wrap]
          cell_styles[style_key] ||= styles.find_or_create_cell_style(protected, color, font_weight: font_weight, wrap: wrap)
        end

        def column_style_for(col_index)
          column_width = table_metrics.formatted_width(col_index)
          # TODO: move lookup/caching behind AutomaticStyles#find_or_create_column_style
          @column_styles_by_width ||= {}
          @column_styles_by_width[column_width] ||= styles.find_or_create_column_style(column_width)
        end

        # ------------------------------
        # Private utility methods

        def populate_spreadsheet!
          logger.info("Populating spreadsheet for #{collection}")
          populate_columns!
          populate_rows!
        end

        def protected?(col_index)
          column = export_table.columns[col_index]
          raise ArgumentError, "Invalid column index: #{col_index.inspect}" unless column

          !column.can_edit?
        end

        # @param table [UCBLIT::Util::ODS::XML::Table::Table] the table
        def populate_columns!
          export_table.columns.each_with_index do |export_column, col_index|
            table.add_column_with_styles(
              export_column.header,
              column_style: column_style_for(col_index),
              header_cell_style: header_cell_style_for(col_index)
            )
          end
        end

        # @param table [UCBLIT::Util::ODS::XML::Table::Table] the table
        def populate_rows!
          export_table.row_count.times(&method(:populate_row))
        end

        def populate_row(row_index)
          export_row = export_table.rows[row_index]
          row_metrics = table_metrics.row_metrics_for(row_index)
          row_height = row_metrics.formatted_row_height
          row = table.add_row(row_height)
          populate_values(export_row, row_metrics, row)
        end

        def populate_values(export_row, row_metrics, row)
          export_row.each_value.with_index do |v, col_index|
            protected = protected?(col_index)
            wrap = row_metrics.wrap?(col_index)
            cell_style = find_or_create_cell_style(protected, wrap: wrap)
            row.set_value_at(col_index, v, cell_style)
          end
        end

      end
    end
  end
end
