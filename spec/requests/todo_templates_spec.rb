require 'rails_helper'

RSpec.describe "TodoTemplates", :type => :request do
  describe "GET /todo_templates" do
    it "works! (now write some real specs)" do
      skip('build valid requests')
      get todo_templates_path
      expect(response).to have_http_status(200)
    end
  end
end
