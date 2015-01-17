require 'spec_helper'
require './models/client'

describe Client do
	before do
		@atag = "sample-22"
	end

	describe '#status' do
		context 'when active' do
			subject { Client.new(atag: @atag) }
			it { expect(subject.status).to eq Client::Status::ACTIVE }
		end

		context 'when rate_limit exceeded' do
			before do
				100.times { Log.create(atag: @atag, created_at: Time.now) }
			end

			after do
				Log.destroy_all
			end

			subject { Client.new(atag: @atag) }
			it { expect(subject.status).to eq Client::Status::SUSPENDED }
		end

		context 'when suspend' do
		end
	end
end
