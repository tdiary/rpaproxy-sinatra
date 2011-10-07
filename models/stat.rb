
# -*- coding: utf-8 -*-
#
require 'mongoid'

class Stat
	include Mongoid::Document
	field :locale, type: String
	field :count, type: Integer
	embeds_many :atag_reports

	def self.create_by_logs(locale)
		atags = {}
		logs = Log.where(locale: locale)
		logs.each do |log|
			atag = log.atag || 'other'
			atags[atag] ||= AtagReport.new(atag: atag)
			atags[atag].count += 1
		end
		atags.each do |atag, atag_report|
			atag_report.ratio = atag_report.count.to_f / logs.count.to_f
		end
		stat = Stat.create(
			locale: locale,
			count: logs.count,
			atag_reports: atags.map{|k,v| v}.sort{|a,b| b.count <=> a.count}
		)
	end
end

class AtagReport
	include Mongoid::Document
	field :atag, type: String
	field :count, type: Integer, default: 0
	field :ratio, type: Float, default: 0

	embedded_in :stat
end
