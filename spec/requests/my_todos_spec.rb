require 'rails_helper'

RSpec.describe "MyTodos", :type => :request do
  describe "GET /my_todos" do
    it "works! (now write some real specs)" do
      skip('build valid requests')
      get my_todos_path
      expect(response).to have_http_status(200)
    end
  end
end
