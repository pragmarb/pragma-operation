# frozen_string_literal: true
require 'pragma/policy'

RSpec.describe Pragma::Operation::Authorization do
  let(:context) { operation.call(current_user: current_user) }

  let(:policy_klass) do
    Class.new(Pragma::Policy::Base) do
      def self.accessible_by(user:, scope:)
        scope.select do |record|
          record.author_id == user.id
        end
      end

      def create?
        user.admin?
      end
    end
  end

  describe '#policy with a block' do
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
        klass.send(:policy, &:policy_klass)
      end
    end

    it 'computes the policy dynamically' do
      expect(operation.call(
        current_user: OpenStruct.new(admin?: true),
        policy_klass: policy_klass
      ).resource[:authorized]).to eq(true)
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

  describe '#authorize_collection' do
    let(:operation) do
      Class.new(Pragma::Operation::Base) do
        class << self
          def name
            'API::V1::Page::Operation::Index'
          end
        end

        def call
          resources = [
            OpenStruct.new(author_id: 1),
            OpenStruct.new(author_id: 2)
          ]

          respond_with status: :ok, resource: authorize_collection(resources)
        end
      end.tap do |klass|
        klass.send(:policy, policy_klass)
      end
    end

    let(:current_user) { OpenStruct.new(id: 1) }

    it 'runs .accessible_by on the policy' do
      expect(context.resource.map(&:author_id)).to eq([1])
    end
  end
end
