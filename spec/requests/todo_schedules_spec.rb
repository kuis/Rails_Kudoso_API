require 'rails_helper'

RSpec.describe "TodoSchedules", :type => :request do
  describe "GET /todo_schedules" do
    it "works! (now write some real specs)" do
      skip('build valid requests')
      get todo_schedules_path
      expect(response).to have_http_status(200)
    end
  end
end
