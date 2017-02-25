# frozen_string_literal: true
RSpec.describe Pragma::Operation::Base do
  let(:operation_klass) do
    Class.new(described_class) do
      step :process

      def process(options)
        true
      end
    end
  end

  it 'runs correctly' do
    expect(operation_klass.call(
      { foo: 'bar' },
      'current_user_id' => 1
    )).to be_success
  end
end
