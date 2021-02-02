require 'spec_helper'

module UCBLIT
  module TIND
    class MARCTable
      describe ColumnGroup do
        describe :new do
          it 'rejects invalid indicators' do
            expect { ColumnGroup.new('856', 0, '_', '2', 'uyz'.chars) }.to raise_error(ArgumentError)
            expect { ColumnGroup.new('856', 0, '2', '_', 'uyz'.chars) }.to raise_error(ArgumentError)
          end
        end
        describe :to_s do
          it 'returns the prefix + subfield codes' do
            cg = ColumnGroup.new('856', 0, '4', '2', 'uyz'.chars)
            cg_str = cg.to_s
            expect(cg_str).to include('85642uyz')
            expect(cg_str).to include('0')
          end
        end
      end
    end
  end
end
