require 'spec_helper'

module UCBLIT
  module TIND
    module Export
      describe ExportCommand do
        before(:each) do
          @base_uri_orig = UCBLIT::TIND::Config.base_uri
          @api_key_orig = UCBLIT::TIND::API.api_key
          @logger_orig = UCBLIT::TIND.logger
        end

        after(:each) do
          UCBLIT::TIND.logger = @logger_orig
          UCBLIT::TIND::API.api_key = @api_key_orig
          UCBLIT::TIND::Config.base_uri = @base_uri_orig
        end

        describe :usage do
          it 'returns the usage' do
            expect(ExportCommand.send(:usage)).to be_a(String)
          end
        end

        describe :list_collection_names do
          it 'lists the collection names' do
            collections = UCBLIT::TIND::API::Collection.all_from_json(File.read('spec/data/collections.json'))
            allow(UCBLIT::TIND::API::Collection).to receive(:all).and_return(collections)

            out = StringIO.new
            ExportCommand.new('-l', out: out).execute!
            expect(out.string).to eq(File.read('spec/data/collection-names.txt'))
          end
        end

        describe :export_collection do
          it 'exports a collection' do
            format = 'csv'
            collection = 'Bancroft Library'
            out = instance_double(IO)

            expect(UCBLIT::TIND::Export).to receive(:export).with(collection, ExportFormat.ensure_format(format), out)
            ExportCommand.new('-f', format, collection, out: out).execute!
          end
        end

        describe 'flags' do
          let(:api_key) { 'ZghOT0eRm4U9s' }
          let(:output_path) { '/tmp/export.ods' }
          let(:collection) { 'Houcun ju shi ji' }

          attr_reader :command

          before(:each) do
            @command = ExportCommand.new('-v', '-k', api_key, '-o', output_path, collection)
          end

          describe '-v' do
            it 'configures a debug-level logger' do
              expect(UCBLIT::TIND.logger.level).to eq(0)
            end
          end

          describe '-k' do
            it 'sets the API key' do
              expect(UCBLIT::TIND::API.api_key).to eq(api_key)
            end
          end

          describe '-o' do
            it 'sets the output file and format' do
              expect(command.options[:outfile]).to eq(output_path)
              expect(command.options[:format]).to eq(ExportFormat::ODS)
            end
          end

          it 'sets the collection' do
            expect(command.options[:collection]).to eq(collection)
          end
        end

        describe 'error handling' do
          it 'prints usage and exits if given bad options' do
            stderr_orig = $stderr
            begin
              out = StringIO.new
              $stderr = out
              expect { ExportCommand.new('-not', '-a', '-valid', '-option') }.to raise_error(SystemExit) do |e|
                expect(e.status).not_to eq(0)
              end
              expected_usage = ExportCommand.send(:usage)
              expect(out.string).to include(expected_usage)
            ensure
              $stderr = stderr_orig
            end
          end

          it 'prints usage and exits in the event of an error' do
            err_class = UCBLIT::TIND::API::APIException
            err_msg = '403 Forbidden'
            expect(UCBLIT::TIND::Export).to receive(:export).and_raise(err_class, err_msg)
            stderr_orig = $stderr
            begin
              out = StringIO.new
              $stderr = out
              expect { ExportCommand.new('Bancroft Library').execute! }.to raise_error(SystemExit) do |e|
                expect(e.status).not_to eq(0)
              end
              expect(out.string).to include(err_msg)
            ensure
              $stderr = stderr_orig
            end
          end
        end
      end
    end
  end
end
