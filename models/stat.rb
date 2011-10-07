
# -*- coding: utf-8 -*-
#
require 'mongoid'

class Stat
	include Mongoid::Document
	# field :date, type: Date
	field :locale, type: String
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
		stat = Stat.create(locale: locale, atag_reports: atags.map{|k,v| v})
		#atags.each do |key, value|
			# stat.atag_reports << value
		# end
		# stat.save
		# stat
	end
end

class AtagReport
	include Mongoid::Document
	field :atag, type: String
	field :count, type: Integer, default: 0
	field :ratio, type: Float, default: 0

	embedded_in :stat
end
