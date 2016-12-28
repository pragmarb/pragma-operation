# frozen_string_literal: true
RSpec.describe Pragma::Operation::Base do
  let(:operation) do
    Class.new(described_class) do
      before :validate_params

      def call
        respond_with(
          status: 200,
          resource: { pong: params[:pong] },
          headers: { 'X-Ping-Time' => Time.now.to_i }
        )
      end

      private

      def validate_params
        return unless params[:pong].empty?

        respond_with!(
          status: 422,
          resource: {
            error_type: :missing_pong,
            error_message: "You must provide a 'pong' parameter."
          }
        )
      end
    end
  end

  let(:params) { { pong: 'HELLO' } }
  let(:current_user) { nil }

  let(:context) { operation.call(params: params, current_user: current_user) }

  it 'responds with a status code' do
    expect(context.status).to eq(:ok)
  end

  it 'responds with a resource' do
    expect(context.resource).to eq(pong: params[:pong])
  end

  it 'responds with headers' do
    expect(context.headers['X-Ping-Time']).to be_instance_of(Fixnum)
  end

  context 'when the response status is invalid' do
    let(:operation) do
      Class.new(described_class) do
        def call
          head :invalid
        end
      end
    end

    it 'raises an InvalidStatusError' do
      expect { context }.to raise_error(Pragma::Operation::InvalidStatusError)
    end
  end

  context 'when the operation does not set a status code' do
    let(:operation) do
      Class.new(described_class) do
        def call
          respond_with status: nil, resource: params[:resource]
        end
      end
    end

    context 'when a resource is set' do
      let(:params) { { resource: 'HELLO' } }

      it 'sets the 200 OK status code' do
        expect(context.status).to eq(:ok)
      end
    end

    context 'when a resource is not set' do
      let(:params) { {} }

      it 'sets the 204 No Content status code' do
        expect(context.status).to eq(:no_content)
      end
    end
  end

  describe '.operation_name' do
    it 'returns the name of the operation' do
      expect(described_class.operation_name).to eq(:base)
    end
  end

  describe '#respond_with!' do
    let(:params) { { pong: '' } }

    it 'halts the execution' do
      expect(context.status).to eq(:unprocessable_entity)
    end
  end

  describe '#head!' do
    let(:operation) do
      Class.new(described_class) do
        before :validate_params

        def call
          respond_with(
            status: 200,
            resource: { pong: params[:pong] }
          )
        end

        private

        def validate_params
          return unless params[:pong].empty?
          head! :unprocessable_entity
        end
      end
    end

    let(:params) { { pong: '' } }

    it 'halts the execution' do
      expect(context.status).to eq(:unprocessable_entity)
    end
  end

  describe '#success?' do
    context 'when the HTTP status code is successful' do
      it 'returns true' do
        expect(context).to be_success
      end
    end

    context 'when the HTTP status code is not successful' do
      let(:params) { { pong: '' } }

      it 'returns false' do
        expect(context).not_to be_success
      end
    end
  end
end
