# frozen_string_literal: true

RSpec.describe Pragma::Operation::Base do
  subject(:result) do
    operation_klass.call(
      { foo: 'bar' },
      { 'current_user_id' => 1 }
    )
  end

  let(:operation_klass) do
    Class.new(described_class) do
      step :process!

      def process!(_options, **)
        true
      end
    end
  end

  it 'runs correctly' do
    expect(result).to be_success
  end

  describe '#respond' do
    context 'with an options hash' do
      it 'builds a response from the options'
    end

    context 'with a symbol' do
      it 'treats the argument as a response template name'
    end

    context 'with a response' do
      it 'responds with the provided response'
    end

    context 'with a symbol and an options hash' do
      it 'treats the argument as a response template name'
      it 'overrides response parameters with the provided options'
    end

    context 'with a response and an options hash' do
      it 'responds with the provided response'
      it 'overrides response parameters with the provided options'
    end
  end

  context '#error' do
    context 'with an options hash' do
      it 'builds an error from the options'
    end

    context 'with a symbol' do
      it 'treats the argument as a response template name'
    end

    context 'with an error' do
      it 'responds with the provided error'
    end

    context 'with a symbol and an options hash' do
      it 'treats the argument as a response template name'
      it 'overrides response parameters with the provided options'
    end

    context 'with an error and an options hash' do
      it 'responds with the provided error'
      it 'overrides response parameters with the provided options'
    end
  end
end
