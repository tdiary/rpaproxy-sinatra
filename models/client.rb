# -*- coding: utf-8 -*-
#
require 'mongoid'
require './models/log'

class Client
	include Mongoid::Document
	include Mongoid::Timestamps

	field :atag, type: String
	field :status, type: Integer, default: 0
	field :suspended_times, type: Integer, default: 0
	index({ atag: 1 }, { unique: true} )

	RATE_LIMIT = 30           # request per minutes
	SUSPENDED_LIMIT = 5       # suspended times to banned
	SUSPENDED_DURATION = 3600 # 1hour

	module Status
		ACTIVE = 0
		SUSPENDED = 1
		BANNED = 2
	end

	after_initialize :status_update

	def status_update
		case status
		when Status::ACTIVE
			if rate_limit_exceed?
				inc(suspended_times: 1)
				if suspended_times > SUSPENDED_LIMIT
					status = Status::BANNED
				else
					self.status = Status::SUSPENDED
				end
			end
		when Status::SUSPENDED
			status = Status::ACTIVE if in_suspend_duration?
		else
			status
		end
	end

	def rate_limit_exceed?
		one_minute_ago = Time.now - 60
		Log.where(:created_at.gte => one_minute_ago).in(atag: atag).count > RATE_LIMIT
	end

	def in_suspend_duration?
		one_hour_ago = Time.now - 3600
		status == Status::SUSPENDED and updated_at < one_hour_ago
	end
end
