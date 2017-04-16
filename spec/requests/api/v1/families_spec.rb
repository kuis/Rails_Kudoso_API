# spec/requests/api/v1/sessions_spec.rb

require 'rails_helper'

describe 'Families API', type: :request do
  before(:all) do
    @user = FactoryGirl.create(:user)
    @device =  FactoryGirl.create(:api_device)
    post '/api/v1/sessions', { device_token: @device.device_token, email: @user.email, password: 'password'}.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    @token = json["token"]
  end

  it 'admin user returns the families list' do
    admin_user = FactoryGirl.create(:user, admin: true)
    post '/api/v1/sessions', { device_token: @device.device_token, email: admin_user.email, password: 'password'}.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
    json = JSON.parse(response.body)
    families = FactoryGirl.create_list(:family, 10)
    get '/api/v1/families', nil,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{json["token"]}\"" }
    json = JSON.parse(response.body)
    expect(json["families"].length).to eq(Family.count)
  end

  it 'denies regular users from listing families' do
      get '/api/v1/families', nil,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\"" }
      expect(response.status).to eq(403)
  end

  it 'returns family info for users family' do
    get "/api/v1/families/#{@user.member.family.id}", nil,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\"" }
    expect(response.status).to eq(200)
  end
  it 'denies family info for users family' do
    get "/api/v1/families/#{@user.member.family.id + 1}", nil,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\"" }
    expect(response.status).to eq(404)
  end

  it 'allows updates to family information for parents' do
    patch "/api/v1/families/#{@user.member.family.id}", { default_time: 120*60, default_filter: 'moderate', name: 'Smith Family'}.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\"" }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    expect(json["family"]["name"]).to eq('Smith Family')
    expect(json["family"]["default_filter"]).to eq('moderate')
    expect(json["family"]["default_screen_time"].to_i).to eq(120*60)
  end

  it 'allows updates to family device categories' do
    device_categories = FactoryGirl.create_list(:device_category, 4)
    postHash = Hash.new
    device_categories.each do |cat|
      postHash[cat.id] ||= Hash.new
      postHash[cat.id]["amount"] = rand(1..5)
    end
    patch "/api/v1/families/#{@user.member.family.id}", { device_categories: postHash}.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\"" }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    expect(@user.family.family_device_categories.count).to eq(device_categories.count)
  end

  it 'allows updates to family time zone' do
    timezone = @user.family.timezone
    loop do
      timezone = ActiveSupport::TimeZone.us_zones.collect{|tz| tz.name }.sample
      break if timezone != @user.family.timezone
    end


    patch "/api/v1/families/#{@user.member.family.id}", { timezone: timezone}.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\"" }
    expect(response.status).to eq(200)
    @user.family.reload
    expect(@user.family.timezone).to eq(timezone)
  end
end
