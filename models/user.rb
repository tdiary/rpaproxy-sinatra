# -*- coding: utf-8 -*-
#
require 'mongoid'

class User
	include Mongoid::Document
	field :uid, type: String
	field :name, type: String
	field :url, type: String
	field :screen_name, type: String
	has_many :proxies

	validates_presence_of :uid, :name, :screen_name
	validates_uniqueness_of :uid
	index :uid, unique: true

	# TODO: URIにはhttp/httpsスキームのみ登録可能とする

	def self.find_or_create_with_omniauth(auth)
		user = where(uid: auth['uid']).first
		unless user
			user = create! do |user|
				user.uid = auth['uid']
				user.name = auth['info']['name']
				user.screen_name = auth['info']['nickname']
			end
		end
		user
	end
end

