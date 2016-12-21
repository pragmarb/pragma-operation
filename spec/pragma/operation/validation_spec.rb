# frozen_string_literal: true
RSpec.describe Pragma::Operation::Authorization do
  let(:context) { operation.call(params: params) }

  describe '#authorize' do
    let(:operation) do
      Class.new(Pragma::Operation::Base) do
        # rubocop:disable Lint/ParenthesesAsGroupedExpression
        contract (Class.new do
          attr_reader :errors
          @errors = []

          def initialize(resource)
          end

          def validate(params)
            if params[:pong].empty?
              errors << ['pong cannot be empty']
            end
          end
        end)
        # rubocop:enable Lint/ParenthesesAsGroupedExpression

        def call
          resource = OpenStruct.new

          respond_with status: :ok, resource: {
            valid: validate(resource)
          }
        end
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
        # rubocop:disable Lint/ParenthesesAsGroupedExpression
        contract (Class.new do
          attr_reader :errors
          @errors = []

          def initialize(resource)
          end

          def validate(params)
            if params[:pong].empty?
              errors << ['pong cannot be empty']
            end
          end
        end)
        # rubocop:enable Lint/ParenthesesAsGroupedExpression

        def call
          resource = OpenStruct.new
          validate! resource

          respond_with status: :ok, resource: {
            valid: validate(resource)
          }
        end
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
        expect(context.resource[:meta][:errors]).to eq(['pong cannot be empty'])
      end
    end
  end
end
