# -*- coding: utf-8 -*-
#
require 'mongoid'
require './models/log'

class Client
	module Status
		ACTIVE = "active"
		SUSPENDED = "suspended"
		BANNED = "banned"
	end

	include Mongoid::Document
	include Mongoid::Timestamps

	field :atag,            type: String
	field :status,          type: String,  default: Status::ACTIVE
	field :suspended_times, type: Integer, default: 0
	field :suspended_at,    type: DateTime

	index({ atag: 1 }, { unique: true} )
	validates_uniqueness_of :atag

	RATE_LIMIT = 30           # request per minutes
	SUSPENDED_DURATION = 3600 # 1hour

	# after_initialize :update_status

	def update_status
		case status
		when Status::ACTIVE
			if rate_limit_exceed?
				self.suspended_times += 1
				self.status = Status::SUSPENDED
				self.suspended_at = Time.now
			end
		when Status::SUSPENDED
			self.status = Status::ACTIVE unless in_suspend_duration?
		when Status::BANNED
			self.status = Status::ACTIVE
		end
	end

	def rate
		one_minute_ago = Time.now - 60
		Log.where(:created_at.gte => one_minute_ago).in(atag: atag).count
	end

	def rate_limit_exceed?
		rate > RATE_LIMIT
	end

	def in_suspend_duration?
		return false if status != Status::SUSPENDED
		return true unless suspended_at

		one_hour_ago = Time.now - 3600
		suspended_at > one_hour_ago
	end

	def to_s
		"#{atag}: #{status}: #{suspended_times}: #{suspended_at}: #{rate}/#{RATE_LIMIT}"
	end
end
