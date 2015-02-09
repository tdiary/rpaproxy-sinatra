# -*- coding: utf-8 -*-
#
require 'mongoid'

class Log
	include Mongoid::Document
	field :atag, type: String
	field :locale, type: String
	field :created_at, type: DateTime
	field :success, type: Boolean
	field :response, type: Float

	belongs_to :proxy
	index({ created_at: 1 })
end
