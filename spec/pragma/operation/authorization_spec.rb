# frozen_string_literal: true
require 'pragma/policy'

RSpec.describe Pragma::Operation::Authorization do
  let(:context) { operation.call(current_user: current_user) }

  let(:policy_klass) do
    Class.new(Pragma::Policy::Base) do
      def create?
        user.admin?
      end
    end
  end

  describe '#authorize' do
    let(:operation) do
      Class.new(Pragma::Operation::Base) do
        class << self
          def name
            'API::V1::Page::Operation::Create'
          end
        end

        def call
          resource = OpenStruct.new

          respond_with status: :ok, resource: {
            authorized: authorize(resource)
          }
        end
      end.tap do |klass|
        klass.send(:policy, policy_klass)
      end
    end

    context 'when the user is authorized' do
      let(:current_user) { OpenStruct.new(admin?: true) }

      it 'returns true' do
        expect(context.resource[:authorized]).to eq(true)
      end
    end

    context 'when the user is not authorized' do
      let(:current_user) { OpenStruct.new(admin?: false) }

      it 'returns false' do
        expect(context.resource[:authorized]).to eq(false)
      end
    end
  end

  describe '#authorize!' do
    let(:operation) do
      Class.new(Pragma::Operation::Base) do
        class << self
          def name
            'API::V1::Page::Operation::Create'
          end
        end

        def call
          resource = OpenStruct.new
          authorize! resource

          respond_with status: :ok, resource: resource
        end
      end.tap do |klass|
        klass.send(:policy, policy_klass)
      end
    end

    context 'when the user is authorized' do
      let(:current_user) { OpenStruct.new(admin?: true) }

      it 'runs the operation' do
        expect(context).to be_success
      end
    end

    context 'when the user is not authorized' do
      let(:current_user) { OpenStruct.new(admin?: false) }

      it 'halts the execution' do
        expect(context).not_to be_success
      end

      it 'responds with the 403 Forbidden status code' do
        expect(context.status).to eq(:forbidden)
      end

      it 'responds with error details' do
        expect(context.resource[:error_type]).to eq(:forbidden)
      end
    end
  end
end
