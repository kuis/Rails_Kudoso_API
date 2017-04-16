# spec/requests/api/v1/todo_templates_spec.rb

require 'rails_helper'

describe 'Todo Schedules API', type: :request do
  before(:all) do

    @user = FactoryGirl.create(:user)
    @member = FactoryGirl.create(:member, family_id: @user.family_id)
    @todos = FactoryGirl.create_list(:my_todo, 3, member_id: @member.id)
    @device =  FactoryGirl.create(:api_device)
    post '/api/v1/sessions', { device_token: @device.device_token, email: @user.email, password: 'password'}.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    @token = json["token"]
  end

  it 'should allow creating recurring rules ' do
    todo_schedule = @todos.sample.todo_schedule
    rule = IceCube::Rule.weekly.day(:friday)
    post "/api/v1/families/#{@user.family.id}/todos/#{todo_schedule.todo_id}/todo_schedules/#{todo_schedule.id}/schedule_rrules",
          { rule: rule.to_hash}.to_json,
          { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""  }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    expect(json["schedule_rrule"]["rule"].deep_symbolize_keys!).to eq(rule.to_hash)
  end


  it 'should allow recurring rules to be updated' do
    todo_schedule = @todos.sample.todo_schedule
    schedule_rrule = todo_schedule.schedule_rrules.first
    expect(schedule_rrule.valid?).to be_truthy
    orig_rule = schedule_rrule.rule.to_hash
    rule = IceCube::Rule.weekly.day(:monday)
    expect(orig_rule).to_not eq(rule.to_hash)
    patch "/api/v1/families/#{@user.family.id}/todos/#{todo_schedule.todo_id}/todo_schedules/#{todo_schedule.id}/schedule_rrules/#{schedule_rrule.id}",
          { rule: rule.to_hash}.to_json,
          { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""  }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    expect(json["schedule_rrule"]["rule"].deep_symbolize_keys!).to eq(rule.to_hash)
  end

  it 'should allow recurring rules to be deleted' do
    todo_schedule = @todos.sample.todo_schedule
    schedule_rrule = todo_schedule.schedule_rrules.first

    delete "/api/v1/families/#{@user.family.id}/todos/#{todo_schedule.todo_id}/todo_schedules/#{todo_schedule.id}/schedule_rrules/#{schedule_rrule.id}",
          nil,
          { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""  }
    expect(response.status).to eq(200)
  end



end
