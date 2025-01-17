# frozen_string_literal: true

RSpec.describe Truemail::Log::Serializer::ValidatorJson do
  describe 'inheritance' do
    specify { expect(described_class).to be < Truemail::Log::Serializer::ValidatorBase }
  end

  describe '.call' do
    subject(:json_serializer) { described_class.call(validator_instance) }

    let(:validator_instance) do
      create_validator(
        validation_type,
        success: success_status,
        configuration: create_configuration(validation_type_for: { 'somedomain.com' => :regex })
      )
    end

    shared_context 'serialized json' do
      %i[whitelist regex mx smtp].each do |validation_layer_name|
        describe "#{validation_layer_name} validation" do
          let(:validation_type) { validation_layer_name }

          it 'returns serialized json' do
            expect(json_serializer).to match_json_schema('validator')
          end
        end
      end
    end

    context 'with successful validation result' do
      let(:success_status) { true }

      include_context 'serialized json'
    end

    context 'with fail validation result' do
      let(:success_status) { false }

      context 'when smtp errors not includes ASCII-8BIT chars' do
        include_context 'serialized json'
      end

      context 'when smtp errors includes ASCII-8BIT chars' do
        let(:error_context_with_ascii_8bit) { "\xD3\xE4\xB2\xBB\xD4" }
        let(:validator_instance) do
          create_validator(
            validation_type,
            success: success_status,
            rcptto_error: error_context_with_ascii_8bit,
            configuration: create_configuration(validation_type_for: { 'somedomain.com' => :regex })
          )
        end

        it 'replaces all invalid chars' do
          encoded_utf8_string = JSON.parse(json_serializer)['smtp_debug'].first.dig('errors', 'rcptto')
          expect(encoded_utf8_string.size).to eq(3)
          expect(encoded_utf8_string).to eq("\uFFFD䲻\uFFFD")
        end

        include_context 'serialized json'
      end
    end
  end
end
