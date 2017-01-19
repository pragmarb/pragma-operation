# frozen_string_literal: true
require 'pragma/contract'

RSpec.describe Pragma::Operation::Validation do
  let(:context) { operation.call(params: params) }

  let(:contract_klass) do
    Class.new(Pragma::Contract::Base) do
      property :pong

      validation :default do
        required(:pong).filled
      end
    end
  end

  describe '#contract with a block' do
    let(:operation) do
      Class.new(Pragma::Operation::Base) do
        def call
          respond_with status: :ok, resource: {
            valid: validate(OpenStruct.new)
          }
        end
      end.tap do |klass|
        klass.send(:contract, &:contract_klass)
      end
    end

    it 'computes the contract dynamically' do
      expect(operation.call(
        params: { pong: 'cia' },
        contract_klass: contract_klass
      ).resource[:valid]).to eq(true)
    end
  end

  describe '#validate' do
    let(:operation) do
      Class.new(Pragma::Operation::Base) do
        def call
          respond_with status: :ok, resource: {
            valid: validate(OpenStruct.new)
          }
        end
      end.tap do |klass|
        klass.send(:contract, contract_klass)
      end
    end

    context 'when the resource is valid' do
      let(:params) { { pong: 'PONG' } }

      it 'returns true' do
        expect(context.resource[:valid]).to eq(true)
      end
    end

    context 'when the resource is not valid' do
      let(:params) { { pong: '' } }

      it 'returns false' do
        expect(context.resource[:valid]).to eq(false)
      end
    end
  end

  describe '#validate!' do
    let(:operation) do
      Class.new(Pragma::Operation::Base) do
        def call
          validate! OpenStruct.new
          respond_with status: :ok, resource: nil
        end
      end.tap do |klass|
        klass.send(:contract, contract_klass)
      end
    end

    context 'when the resource is valid' do
      let(:params) { { pong: 'HELLO' } }

      it 'runs the operation' do
        expect(context).to be_success
      end
    end

    context 'when the resource is not valid' do
      let(:params) { { pong: '' } }

      it 'halts the execution' do
        expect(context).not_to be_success
      end

      it 'responds with the 422 Unprocessable Entity status code' do
        expect(context.status).to eq(:unprocessable_entity)
      end

      it 'responds with error details' do
        expect(context.resource[:meta][:errors]).to eq(pong: ['must be filled'])
      end
    end
  end
end
