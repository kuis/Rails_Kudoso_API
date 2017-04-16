module Api
  module V1
    class AppsDevicesController < ApiController

      resource_description do
        short 'Apps'
        formats ['json']
        api_version "v1"
        error 404, "Missing"
        error 500, "Server processing error (check messages object)"
        description <<-EOS
          == Apps
          Used for registering and tracking applications with their associated devices
        EOS
      end

      api :GET, "/v1/family/<family_id>/devices/<device_id>/apps", "Get list of installed apps on device"
      def index
        messages = init_messages
        begin
          @family = Family.find(params[:family_id])
          @device = @family.devices.find(params[:device_id])
          if @current_user.try(:admin) || (@current_member.try(:family) == @family )
            render :json => { apps: @device.apps, :messages => messages }, :status => 200
          else
            messages[:error] << 'You are not authorized to do this.'
            render :json => { :messages => messages }, :status => 403
          end

        rescue ActiveRecord::RecordNotFound
          messages[:error] << 'Family or Device not found.'
          render :json => { :messages => messages }, :status => 404
        rescue
          messages[:error] << 'A server error occurred.'
          render :json => { :messages => messages }, :status => 500
        end
      end

      api :POST, "/v1/family/<family_id>/devices/<device_id>/apps", "Add application(s) to device"
      param :app, Hash, desc: "App object consisting of (uuid is required): { 'app' : { 'name' : 'app_name', 'uuid' : 'com.kudoso.Kudoso', installed_at: 1442262846, 'url' : 'http://app_url', 'publisher' : 'Publisher Name', icon' : { 'content-type' : 'image/png', 'content' : 'base64 string' } } } "
      param :apps, Array, desc: "Array of app objects"
      def create
        messages = init_messages
        begin
          @family = Family.find(params[:family_id])
          @device = @family.devices.find(params[:device_id])
          if @current_user.try(:admin) || (@current_member.try(:family) == @family )
            good = true
            if params[:apps] && params[:apps].is_a?(Array)
              params[:apps].each { |app| good = add_app(app, @device) && good }
            else
              good = add_app(params[:app], @device) && good
            end
            if good
              render :json => { apps: @device.apps, :messages => messages }, :status => 200
            else
              messages[:error] << 'Unable to add application record'
              render :json => { :messages => messages }, :status => 400
            end

          else
            messages[:error] << 'You are not authorized to do this.'
            render :json => { :messages => messages }, :status => 403
          end

        rescue ActiveRecord::RecordNotFound
          messages[:error] << 'Family or Device not found.'
          render :json => { :messages => messages }, :status => 404
        rescue
          messages[:error] << 'A server error occurred.'
          render :json => { :messages => messages }, :status => 500
        end
      end

      private

      def add_app(new_app, device)
        return false if device.nil? || !new_app.is_a?(Hash)
        app = App.find_or_create_by(uuid: new_app[:uuid])
        app.name ||= new_app[:name]
        app.publisher ||= new_app[:publisher]
        app.url ||= new_app[:url]
        app.icon = parse_image_data(new_app[:icon]) if new_app[:icon]
        if app.save
          app_device = AppDevice.find_or_create_by(app_id: app.id, device_id: device.id)
          if app_device.valid? && new_app[:installed_at]
            app_device.update_attribute(:installed_at, Time.at(new_app[:installed_at]))
          end
          return true if app_device.valid?
        end
        return false
      end




    end
  end
end