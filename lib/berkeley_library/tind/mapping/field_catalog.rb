require 'berkeley_library/tind/mapping/tind_subfield_util'
require 'berkeley_library/tind/mapping/misc'

module BerkeleyLibrary
  module TIND
    module Mapping

      class DataFieldsCatalog
        include Misc
        include TindSubfieldUtil
        include CsvMapper
        include Util
        include AdditionalDatafieldProcess
        include BerkeleyLibrary::Logging

        attr_reader :control_fields
        attr_reader :data_fields_group
        attr_reader :data_fields_880_group
        attr_reader :data_fields_880_00
        attr_reader :mms_id

        def initialize(record)
          @control_fields = []
          @data_fields_group = []
          @data_fields_880_group = []
          @data_fields_880_00 = []
          @mms_id = ''

          @data_fields = []
          @data_fields_880 = []
          @alma_field_tags = []

          init(record)
        end

        def init(record)
          prepare_catalog(record)
          @mms_id = alma_mms_id
          @data_fields_group = prepare_group(@data_fields)
          @data_fields_880_group = prepare_group(@data_fields_880)
        end

        def prepare_catalog(record)
          clean_fields = clean_subfields(record.fields)
          clean_fields.each do |f|
            next if added_control_field?(f)
            next if added_880_field?(f)

            tag = f.tag
            next unless (found_in_mapper? tag) && (no_pre_existed_field? tag)

            @data_fields << f
            @alma_field_tags << f.tag
          end
        end

        def prepare_group(from_fields)
          datafields_hash = { normal: [], pre_tag: [], pre_tag_subfield: [] }
          from_fields.each do |f|
            # a regular field tag, or a tag value from 880 field captured from subfield6
            tag = origin_mapping_tag(f)
            next unless tag

            rule = rules[Util.tag_symbol(tag)]
            assing_field(rule, f, datafields_hash)
          end

          datafields_hash
        end

        private

        # f is either from field whose tag having a match in csv mapping file - 'from tag' column
        def assing_field(rule, f, datafields_hash)
          if rule.pre_existed_tag then datafields_hash[:pre_tag] << f
          elsif rule.pre_existed_tag_subfield then datafields_hash[:pre_tag_subfield] << f
          else  datafields_hash[:normal] << f
          end
        end

        # 880 field with a subfield6 including a tag belong to origin tags defined in csv file
        def qualified_880_field?(f)
          return false unless referred_tag(f)

          found_in_mapper?(referred_tag(f))
        end

        def added_control_field?(f)
          return false unless ::MARC::ControlField.control_tag?(f.tag)

          @control_fields << f
          true
        end

        def added_880_field?(f)
          return false unless f.tag == '880'

          # adding 880 datafield with "non-subfield6" to "00" group for keeping this record in TIND
          # with log information, to let users correcting or removing this datafield from TIND record
          @data_fields_880_00 << f unless valid_subfield6?(f)

          if qualified_880_field?(f)
            subfield6_endwith_00?(f) ? @data_fields_880_00 << f : @data_fields_880 << f
          end

          true
        end

        def valid_subfield6?(f)
          return true if subfield6?(f)

          logger.warn("880 field has no subfield 6 #{f.inspect}")

          false
        end

        def add_to_datafields_with_pre_existed_field(f, rule)
          @data_fields_with_pre_existed_field << f if rule.pre_existed_tag
        end

        def add_to_datafields_with_pre_existed_subfield(f, rule)
          @data_fields_with_pre_existed_subfield << f if rule.pre_existed_tag_subfield
        end

        def add_to_datafields_normal(f, rule)
          @data_fields_normal << f if rule.pre_existed_tag_subfield.nil? && rule.pre_existed_tag.nil?
        end

        # Is the origin_tag of a field has related from_tag in csv file?
        def found_in_mapper?(tag)
          from_tags.include? tag
        end

        # If tag is listed in csv_mapper.one_occurrence_tags
        # Check pre_existed field of this tag
        # make sure to keep the first datafield for an one_occurrence_tag defined in csv mapping file
        def no_pre_existed_field?(tag)
          # no one-occurrence defined in csv
          return true unless one_occurrence_tags.include? tag

          # Checking the exsisting regular fields include the one-occurrence field defined in the csv
          return false if @alma_field_tags.compact.include? tag

          true
        end

        def alma_mms_id
          f_001 = @control_fields.find { |f| f if f.tag == '001' }
          return nil unless f_001

          f_001.value
        end

      end
    end
  end
end
