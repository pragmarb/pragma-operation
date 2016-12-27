# frozen_string_literal: true
require 'pragma/decorator'

RSpec.describe Pragma::Operation::Decoration do
  let(:context) { operation.call }

  let(:decorator_klass) do
    Class.new(Pragma::Decorator::Base) do
      property :title
    end
  end

  describe '#decorate' do
    let(:operation) do
      Class.new(Pragma::Operation::Base) do
        def call
          respond_with status: :ok, resource: decorate(OpenStruct.new(
            title: 'Test',
            foo: 'bar'
          )).to_hash
        end
      end.tap do |klass|
        klass.send(:decorator, decorator_klass)
      end
    end

    it 'decorates the resource' do
      expect(context.resource).to eq('title' => 'Test')
    end
  end
end
