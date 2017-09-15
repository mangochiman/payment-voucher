class Workings < ActiveRecord::Base
  set_table_name :workings
  set_primary_key :workings_id

  default_scope :conditions => "#{self.table_name}.voided = 0"

  def self.new_workings(params)
     workings = Workings.new
     workings.name = params[:name]
     workings.percent = params[:percent]
     workings.value = params[:value]
     return workings
  end

  def self.edit_workings(params)
     workings = Workings.find(params[:workings_id])
     workings.name = params[:name]
     workings.percent = params[:percent]
     workings.value = params[:value]
     return workings
  end

  def self.void_workings(workings_id)
    workings = Workings.find(workings_id)
    workings.voided = 1
    return workings
  end

end
