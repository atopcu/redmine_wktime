# ERPmine - ERP for service industry
# Copyright (C) 2011-2018  Adhi software pvt ltd
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
class WkschedulingController < WkbaseController
  unloadable
  menu_item :wkattendance
  rescue_from Query::StatementInvalid, :with => :query_statement_invalid

  helper :issues
  helper :projects
  helper :queries
  include QueriesHelper
  include WktimeHelper


	def index	
		@schedulesShift = validateERPPermission("S_SHIFT")
		@editShiftSchedules = validateERPPermission("E_SHIFT")
		if params[:year] and params[:year].to_i > 1900
			@year = params[:year].to_i
			if params[:month] and params[:month].to_i > 0 and params[:month].to_i < 13
				@month = params[:month].to_i
			end
		end
		@year ||= User.current.today.year
		@month ||= User.current.today.month
		
		@calendar = Redmine::Helpers::Calendar.new(Date.civil(@year, @month, 1), current_language, :month)
		userIds = schedulingFilterValues 
		shiftId = session[controller_name][:shift_id]
		dayOff = session[controller_name][:day_off]		
		unless params[:generate].blank? || !to_boolean(params[:generate])
			@shiftRoles.each do | entry |
				Rails.logger.info("=========== PrioritySchedule Call============")
				ScheduleStrategy.new.schedule('P', entry.location_id, entry.department_id, @calendar.startdt, @calendar.enddt)
				Rails.logger.info("=========== Round Robin Call============")
				ScheduleStrategy.new.schedule('RR', entry.location_id, entry.department_id, @calendar.startdt, @calendar.enddt)
			end
		end
		unless shiftId.blank?
			@shiftObj = WkShiftSchedule.where(:schedule_date => @calendar.startdt..@calendar.enddt, :user_id => userIds, :shift_id => shiftId.to_i, :schedule_type => 'S').order(:schedule_date, :user_id, :shift_id)
		else
			@shiftObj = WkShiftSchedule.where(:schedule_date => @calendar.startdt..@calendar.enddt, :user_id => userIds, :schedule_type => 'S').order(:schedule_date, :user_id, :shift_id)
		end
		
		@shiftPreference = WkShiftSchedule.where(:schedule_date => @calendar.startdt..@calendar.enddt, :user_id => userIds, :schedule_type => 'P').order(:schedule_date, :user_id, :shift_id)
		unless dayOff.blank?
			@shiftObj = @shiftObj.where(:schedule_as => dayOff)
			@shiftPreference = @shiftPreference.where(:preference_type => dayOff)
		end
		day = @calendar.startdt
		@schedulehash = Hash.new 
		while day <= @calendar.enddt
			arr = []
			isScheduled = false
			@shiftObj.each do |entry|
				if entry.schedule_date == day
					isScheduled = true
					arr << ((entry.user.name.to_s) + " - " + (entry.shift.name.to_s) +" - "+ (entry.schedule_as.to_s) +" - "+ (entry.schedule_type.to_s))				
				end
			end
			unless isScheduled
				@shiftPreference.each do |entry|
					if entry.schedule_date == day
						arr << ((entry.user.name.to_s) + " - " + (entry.shift.name.to_s) +" - "+ (entry.schedule_as.to_s)+" - "+ (entry.schedule_type.to_s))
					end
				end
			end					
			@schedulehash["#{day}"] = arr
			day = day + 1
		end 
	end
	
	def edit	
		@schedulesShift = validateERPPermission("S_SHIFT")
		@editShiftSchedules = validateERPPermission("E_SHIFT")					
		userIds = schedulingFilterValues
		scheduleDate =  params[:date]
		shiftId = session[controller_name][:shift_id]
		dayOff = session[controller_name][:day_off]
		
		if !scheduleDate.blank? && !shiftId.blank?
			@shiftObj = WkShiftSchedule.where(:schedule_date => scheduleDate, :user_id => userIds, :shift_id => shiftId.to_i, :schedule_type => 'S').order(:schedule_date, :user_id) 
			@shiftPreference = WkShiftSchedule.where(:schedule_date => scheduleDate, :user_id => userIds, :shift_id => shiftId.to_i, :schedule_type => 'P').order(:schedule_date, :user_id)
		elsif !scheduleDate.blank? && shiftId.blank?
			@shiftObj = WkShiftSchedule.where(:schedule_date => scheduleDate, :user_id => userIds, :schedule_type => 'S').order(:schedule_date, :user_id) 
			@shiftPreference = WkShiftSchedule.where(:schedule_date => scheduleDate, :user_id => userIds, :schedule_type => 'P').order(:schedule_date, :user_id)
		end	
		unless dayOff.blank?
			@shiftObj = @shiftObj.where(:schedule_as => dayOff)
			@shiftPreference = @shiftPreference.where(:preference_type => dayOff)
		end		
	end
	
	def update
		errorMsg = ""
		@schedulingEntries = nil
		for i in 1..params[:rowCount].to_i-1
			if to_boolean(params[:isscheduled])
				# createSchedulingObject(WkShiftSchedule, params["schedule_id#{i}"])
				@schedulingEntries = WkShiftSchedule.where(:schedule_date => params["scheduling_date#{i}"], :user_id => params["user_id#{i}"], :schedule_type => 'S').first_or_initialize(:schedule_date => params["scheduling_date#{i}"], :user_id => params["user_id#{i}"], :schedule_type => 'S')
				# @schedulingEntries.schedule_date = params["scheduling_date#{i}"]
				@schedulingEntries.schedule_as = to_boolean(params["day_off#{i}"]) ? 'W' : 'O' unless params["day_off#{i}"].blank?
				# @schedulingEntries.schedule_type = "S"
			else
				# createSchedulingObject(WkShiftSchedule, params["schedule_id#{i}"])
				@schedulingEntries = WkShiftSchedule.where(:schedule_date => params["scheduling_date#{i}"], :user_id => params["user_id#{i}"], :schedule_type => 'P').first_or_initialize(:schedule_date => params["scheduling_date#{i}"], :user_id => params["user_id#{i}"], :schedule_type => 'P')
				# @schedulingEntries.schedule_date = params["scheduling_date#{i}"]
				if params["day_off#{i}"] == "1"
					@schedulingEntries.schedule_as = 'O'
				elsif params["user_id#{i}"].to_i == User.current.id
					@schedulingEntries.schedule_as = 'W'
				end	
				# @schedulingEntries.schedule_type = "P"				
			end			
			#@schedulingEntries.user_id = params["user_id#{i}"]
			@schedulingEntries.shift_id = params["shifts#{i}"]
			if @schedulingEntries.schedule_type == "P"	
				from = getStartDay(@schedulingEntries.schedule_date)
				to = from + 6.days
				from.upto(to) do |schDt|
					unless schDt == @schedulingEntries.schedule_date
						dupSchedule = WkShiftSchedule.where(:schedule_date => schDt, :user_id => params["user_id#{i}"], :schedule_type => 'P').first_or_initialize(:schedule_date => schDt, :user_id => params["user_id#{i}"], :schedule_type => 'P')
						dupSchedule.shift_id = @schedulingEntries.shift_id
						dupSchedule.save 
					end
				end
			end
			@schedulingEntries.save
		end
		redirect_to :controller => controller_name,:action => 'index' , :tab => 'wkscheduling'
		flash[:notice] = l(:notice_successful_update)
		flash[:error] = errorMsg unless errorMsg.blank?
	end
	
	def createSchedulingObject(model, id)
		unless id.blank?
			@schedulingEntries = model.find(id.to_i)
		else
			@schedulingEntries = model.new
		end
	end
	
	def schedulingFilterValues		
		userIds = User.current.id
		set_filter_session
		departmentId =  session[controller_name][:department_id]
		locationId =  session[controller_name][:location_id]
		if @schedulesShift
			if (!departmentId.blank? && departmentId.to_i != 0 ) && !locationId.blank?
				entries = WkUser.includes(:user).where(:department_id => params[:department_id].to_i, :location_id => params[:location_id].to_i)
				@shiftRoles = WkShiftRole.where(:department_id => params[:department_id].to_i, :location_id => params[:location_id].to_i)
			elsif (!departmentId.blank? && departmentId.to_i != 0 ) && locationId.blank?
				entries = WkUser.includes(:user).where(:department_id => params[:department_id].to_i)
				@shiftRoles = WkShiftRole.where(:department_id => params[:department_id].to_i)
			elsif (departmentId.blank? || departmentId.to_i == 0 ) && !locationId.blank?
				entries = WkUser.includes(:user).where(:location_id => params[:location_id].to_i)
				@shiftRoles = WkShiftRole.where(:location_id => params[:location_id].to_i)
			else
				entries = WkUser.includes(:user).all
				@shiftRoles = WkShiftRole.order(:location_id, :department_id)
			end
			if !params[:name].blank?
				entries = entries.where("users.type = 'User' and LOWER(users.firstname) like LOWER('%#{params[:name]}%') or LOWER(users.lastname) like LOWER('%#{params[:name]}%')")
			end
			userIds = entries.pluck(:user_id) 
		end
		userIds
	end
	
	def set_filter_session
		if params[:searchlist].blank? && session[controller_name].nil?
			session[controller_name] = {:location_id => params[:location_id], :department_id => params[:department_id], :shift_id => params[:shift_id]} 
		elsif params[:searchlist] == controller_name
			session[controller_name][:location_id] = params[:location_id]
			session[controller_name][:department_id] = params[:department_id]
			session[controller_name][:shift_id] =  params[:shift_id]
			session[controller_name][:day_off] =  params[:day_off]
		end
	end
end
