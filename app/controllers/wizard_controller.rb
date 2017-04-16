class WizardController < ApplicationController
  before_action :authenticate_user!

  def index
    case current_user.wizard_step
      when 1
        @default_time = '2 Hours'
        case current_user.family.default_screen_time
          when 1800
            @default_time = '1/2 Hour'
          when 3600
            @default_time = '1 Hour'
          when 5400
            @default_time = '1.5 Hours'
        end
      when 3
        @family_device_categories = Array.new


        DeviceCategory.find_each do |device_category|
          @family_device_categories << { id: device_category.id,
                                         name: device_category.name,
                                         description: device_category.description,
                                         amount: current_user.family.family_device_categories.where(device_category_id: device_category.id).first.try(:amount) || 0 }
        end

    end
  end

  def create
    if params["back"]
      if current_user.wizard_step > 1
        current_user.update_attribute(:wizard_step, current_user.wizard_step-1 )
      elsif current_user.wizard_step == 0
        current_user.update_attribute(:wizard_step, 4 )
      end

    else
      if (1..3).include?(current_user.wizard_step)
        current_user.update_attribute(:wizard_step, current_user.wizard_step+1 )
      else
        current_user.update_attribute(:wizard_step, 0 )
      end
    end

    respond_to do |format|
      format.json { render json: { step: current_user.wizard_step} }
    end

  end

  def update
    if params[ "step" ].to_i == 1
      current_user.family.default_screen_time = params["default_time"].to_i if params["default_time"]
      current_user.family.default_filter = params["default_filter"].downcase if params["default_filter"]
      current_user.family.timezone = params["time_zone"] if params["time_zone"]
      current_user.family.save
    end

    if params[ "step" ].to_i == 3
       params[ "device_categories" ].each do |key, value|
         unless key.ends_with?('_other')
           id = "#{key}"
           id.slice!('device_category_')
           device_category = FamilyDeviceCategory.find_or_create_by(device_category_id: id.to_i, family_id: current_user.family.id)
           if value.to_i != 4
             device_category.amount = value.to_i
           else
             device_category.amount = params[ "device_categories" ][ "device_category_#{id}_other"].to_i
           end
           device_category.save
           logger.info "Saved device category: #{device_category.inspect}"
         end
       end

    end


    respond_to do |format|
      format.json { render json: { message: "success" } }
    end

  end

end
