require 'spec_helper'
require './models/client'

describe Client do
	before do
		@atag = "sample-22"
		@active_client = Client.new(atag: @atag)
		@suspended_client = Client.new(
			atag: @atag,
			status: Client::Status::SUSPENDED,
			suspended_at: Time.now,
			suspended_times: 1
		)
	end

	after do
		Log.destroy_all
	end

	describe '#status' do
		context 'with active' do
			before do
				@active_client.update_status
			end
			subject { @active_client }
			it { expect(subject.status).to eq Client::Status::ACTIVE }

			context 'when rate_limit has exceeded' do
				before do
					31.times { Log.create(atag: @atag, created_at: Time.now) }
					@active_client.update_status
				end
				subject { @active_client.status }
				it { expect(subject).to eq Client::Status::SUSPENDED }

				describe '#suspended_times' do
					subject { @active_client.suspended_times }
					it { expect(subject).to eq 1 }
				end
			end

			context 'when rate_limit has exceeded 5 times' do
				before do
					31.times { Log.create(atag: @atag, created_at: Time.now) }
					@active_client.suspended_times = Client::SUSPENDED_LIMIT - 1
					@active_client.update_status
				end

				subject { @active_client }
				it { expect(subject.status).to eq Client::Status::BANNED }
			end

			context 'with rate_limit exceeded logs at than 1 minute ago' do
				before do
					31.times { Log.create(atag: @atag, created_at: Time.now - 60) }
					@active_client.update_status
				end
				subject { @active_client }
				it { expect(subject.status).to eq Client::Status::ACTIVE }
			end
		end

		context 'with suspend' do
			subject { @suspended_client }
			it { expect(subject.status).to eq Client::Status::SUSPENDED }

			context 'when 1 hour later' do
				before do
					one_hour_later = Time.now + 3600
					allow(Time).to receive_message_chain(:now).and_return(one_hour_later)
					@suspended_client.update_status
				end

				subject { @suspended_client.status }
				it { expect(subject).to eq Client::Status::ACTIVE }

				describe '#suspended_times' do
					subject { @suspended_client.suspended_times }
					it { expect(subject).to eq 1 }
				end
			end
		end
	end
end
