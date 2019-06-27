# frozen_string_literal: true

RSpec.describe Truemail::Validate::DomainListMatch do
  describe '.check' do
    subject(:list_match_validator) { described_class.check(result_instance) }

    let(:email) { FFaker::Internet.email }
    let(:domain) { email[Truemail::RegexConstant::REGEX_DOMAIN_FROM_EMAIL, 1] }
    let(:result_instance) { Truemail::Validator::Result.new(email: email) }

    before do
      allow(Truemail)
        .to receive_message_chain(:configuration, :whitelist_validation)
        .and_return(whitelist_validation_condition)
    end

    context 'when whitelist validation not configured' do
      let(:whitelist_validation_condition) { false }

      context 'when email domain in white list' do
        specify do
          allow(Truemail).to receive_message_chain(:configuration, :whitelisted_domains).and_return([domain])
          allow(Truemail).to receive_message_chain(:configuration, :blacklisted_domains).and_return([])
          expect { list_match_validator }.to change(result_instance, :success).from(nil).to(true)
        end
      end

      context 'when email domain in black list' do
        specify do
          allow(Truemail).to receive_message_chain(:configuration, :whitelisted_domains).and_return([])
          allow(Truemail).to receive_message_chain(:configuration, :blacklisted_domains).and_return([domain])
          expect { list_match_validator }
            .to change(result_instance, :success).from(nil).to(false)
            .and change(result_instance, :errors).from({}).to({ domain_list_match: Truemail::Validate::DomainListMatch::ERROR })
        end
      end

      context 'when email domain exists on both lists' do
        specify do
          allow(Truemail).to receive_message_chain(:configuration, :whitelisted_domains).and_return([domain])
          allow(Truemail).to receive_message_chain(:configuration, :blacklisted_domains).and_return([domain])
          expect { list_match_validator }.to change(result_instance, :success).from(nil).to(true)
        end
      end

      context 'when email domain exists not on both lists' do
        specify do
          allow(Truemail).to receive_message_chain(:configuration, :whitelisted_domains).and_return([])
          allow(Truemail).to receive_message_chain(:configuration, :blacklisted_domains).and_return([])
          expect { list_match_validator }.not_to change(result_instance, :success)
        end
      end
    end

    context 'when whitelist validation configured' do
      let(:whitelist_validation_condition) { true }

      context 'when email domain whitelisted in configuration' do
        before do
          allow(Truemail).to receive_message_chain(:configuration, :whitelisted_domains).and_return([domain])
        end

        context 'when email domain in white list' do
          specify do
            allow(Truemail).to receive_message_chain(:configuration, :blacklisted_domains).and_return([])
            expect { list_match_validator }.not_to change(result_instance, :success)
          end
        end

        context 'when email domain exists on both lists' do
          specify do
            allow(Truemail).to receive_message_chain(:configuration, :blacklisted_domains).and_return([domain])
            expect { list_match_validator }
              .to change(result_instance, :success).from(nil).to(false)
              .and change(result_instance, :errors).from({}).to({ domain_list_match: Truemail::Validate::DomainListMatch::ERROR })
          end
        end
      end

      context 'when email domain not whitelisted in configuration' do
        before do
          allow(Truemail).to receive_message_chain(:configuration, :whitelisted_domains).and_return([])
        end

        context 'when email domain in black list' do
          specify do
            allow(Truemail).to receive_message_chain(:configuration, :blacklisted_domains).and_return([])
            expect { list_match_validator }
              .to change(result_instance, :success).from(nil).to(false)
              .and change(result_instance, :errors).from({}).to({ domain_list_match: Truemail::Validate::DomainListMatch::ERROR })
          end
        end

        context 'when email domain not exists on both lists' do
          specify do
            allow(Truemail).to receive_message_chain(:configuration, :blacklisted_domains).and_return([])
            expect { list_match_validator }
              .to change(result_instance, :success).from(nil).to(false)
              .and change(result_instance, :errors).from({}).to({ domain_list_match: Truemail::Validate::DomainListMatch::ERROR })
          end
        end
      end
    end
  end
end