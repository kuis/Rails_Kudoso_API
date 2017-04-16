# spec/requests/api/v1/devices_spec.rb

require 'rails_helper'

describe 'Devices API', type: :request do
  before(:each) do
    @device = FactoryGirl.create(:device)
    @api_device =  FactoryGirl.create(:api_device)
  end

  it 'handles an invalid device token' do
    wifi_mac = SecureRandom.hex(12)
    query_str = { device_token: SecureRandom.hex(24), wifi_mac:wifi_mac, udid: SecureRandom.uuid, product_name: 'yahoo', model_name: @device.device_type.name }
    post "/api/v1/devices/#{@device.uuid}/deviceDidRegister", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Signature' => Digest::MD5.hexdigest(ActiveSupport::JSON.encode(query_str) + @api_device.device_token.reverse) }
    expect(response.status).to eq(401)
    expect(JSON.parse(response.body)['messages']['error']).to include('Invalid Device Token')
  end

  it 'handles an invalid signature' do
    wifi_mac = SecureRandom.hex(12)
    query_str = { device_token: @api_device.device_token, wifi_mac:wifi_mac, udid: SecureRandom.uuid, product_name: 'yahoo', model_name: @device.device_type.name }
    post "/api/v1/devices/#{@device.uuid}/deviceDidRegister", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Signature' => Digest::MD5.hexdigest(ActiveSupport::JSON.encode(query_str) + SecureRandom.hex(24)) }
    expect(response.status).to eq(401)
    expect(JSON.parse(response.body)['messages']['error'].first).to match(/Invalid Signature/)
  end

  it 'handles expired api devices' do
    @api_device.expires_at = Time.now - 1.day
    @api_device.save
    wifi_mac = SecureRandom.hex(12)
    query_str = { device_token: @api_device.device_token, wifi_mac:wifi_mac, udid: SecureRandom.uuid, product_name: 'yahoo', model_name: @device.device_type.name }
    post "/api/v1/devices/#{@device.uuid}/deviceDidRegister", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Signature' => Digest::MD5.hexdigest(ActiveSupport::JSON.encode(query_str) + @api_device.device_token.reverse) }
    expect(response.status).to eq(401)
    expect(JSON.parse(response.body)['messages']['error']).to include('Device/application access expired, please update your application code at your app store')
  end

  it 'successfully handles a mobicip deviceDidRegister callback' do
    wifi_mac = SecureRandom.hex(12)
    query_str = { device_token: @api_device.device_token, wifi_mac:wifi_mac, udid: SecureRandom.uuid, product_name: 'yahoo', model_name: @device.device_type.name }
    post "/api/v1/devices/#{@device.uuid}/deviceDidRegister", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Signature' => Digest::MD5.hexdigest(ActiveSupport::JSON.encode(query_str) + @api_device.device_token.reverse) }
    expect(response.status).to eq(200)
    @device.reload
    expect(@device.wifi_mac).to eq(wifi_mac)
  end

  it 'handles an invalid device token' do
    cmd = Faker::Lorem.sentence(3)
    last_seen = 5.minutes.ago
    query_str = { device_token: SecureRandom.hex(24), commandExecuted: cmd, lastReachedAt: last_seen.to_i.to_s }
    patch "/api/v1/devices/#{@device.uuid}/status", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Signature' => Digest::MD5.hexdigest(ActiveSupport::JSON.encode(query_str) + @api_device.device_token.reverse) }
    expect(response.status).to eq(401)
    expect(JSON.parse(response.body)['messages']['error']).to include('Invalid Device Token')
  end

  it 'handles an invalid signature' do
    cmd = Faker::Lorem.sentence(3)
    last_seen = 5.minutes.ago
    query_str = { device_token: @api_device.device_token, commandExecuted: cmd, lastReachedAt: last_seen.to_i.to_s }
    patch "/api/v1/devices/#{@device.uuid}/status", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Signature' => Digest::MD5.hexdigest(ActiveSupport::JSON.encode(query_str) + SecureRandom.hex(24)) }
    expect(response.status).to eq(401)
    expect(JSON.parse(response.body)['messages']['error'].first).to match(/Invalid Signature/)
  end

  it 'handles expired api devices' do
    @api_device.expires_at = Time.now - 1.day
    @api_device.save
    cmd = Faker::Lorem.sentence(3)
    last_seen = 5.minutes.ago
    query_str = { device_token: @api_device.device_token, commandExecuted: cmd, lastReachedAt: last_seen.to_i.to_s }
    patch "/api/v1/devices/#{@device.uuid}/status", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Signature' => Digest::MD5.hexdigest(ActiveSupport::JSON.encode(query_str) + @api_device.device_token.reverse) }
    expect(response.status).to eq(401)
    expect(JSON.parse(response.body)['messages']['error']).to include('Device/application access expired, please update your application code at your app store')
  end

  it 'successfully handles a mobicip stats callback' do
    cmd = Faker::Lorem.sentence(3)
    last_seen = 5.minutes.ago
    query_str = { device_token: @api_device.device_token, commandExecuted: cmd, lastReachedAt: last_seen.to_i.to_s }
    patch "/api/v1/devices/#{@device.udid}/status", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Signature' => Digest::MD5.hexdigest(ActiveSupport::JSON.encode(query_str) + @api_device.device_token.reverse) }
    expect(response.status).to eq(200)
    @device.reload
    expect(@device.commands.last.name).to eq(cmd)
    expect(@device.last_contact.to_i).to eq(last_seen.to_i)
  end

  context 'authenticated user' do
    before(:each) do
      @user = FactoryGirl.create(:user)
      #@member = FactoryGirl.create(:member, family_id: @user.member.family.id)
      @member = Member.create(username: 'thetest', password: 'password', password_confirmation: 'password', birth_date: 10.years.ago, family_id: @user.family_id)
      post '/api/v1/sessions', { device_token: @api_device.device_token, email: @user.email, password: 'password'}.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      @token = json["token"]
    end

    it 'lists existing family devices to a user' do
      device1 = FactoryGirl.create(:device, family: @user.family)
      device2 = FactoryGirl.create(:device, family: @user.family)
      FactoryGirl.create(:device)
      get "/api/v1/families/#{@user.family_id}/devices", nil, { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""   }

      json = JSON.parse(response.body)
      expect(response.status).to eq(200)
      expect(json['devices'].count).to eq 2
      expect(json['devices'].map{|x| x['id']}).to match_array([device1.id, device2.id])
    end

    it 'listing devices does not allow a user to cross family boundaries' do
      device = FactoryGirl.create(:device)
      get "/api/v1/families/#{device.family_id}/devices", nil, { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""   }

      json = JSON.parse(response.body)
      expect(response.status).to eq(403)
      expect(json['messages']['error']).to include('You are not authorized to do this.')
    end

    it 'creates a new device' do
      query_str = { device: { mac_address: 'aa:11:bb:22:ef', name: 'aa:11:bb:22:ef'} }
      post "/api/v1/families/#{@user.family_id}/devices", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""   }
      expect(response.status).to eq(200)
    end

    it 'finds a device with the same mac_address instead of creates' do
      query_str = { device: { mac_address: 'aa:11:bb:22:ef', name: 'aa:11:bb:22:ef'} }
      post "/api/v1/families/#{@user.family_id}/devices", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""   }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      device_id = json["device"]["id"]
      expect(device_id).to_not be_nil
      query_str = { device: { mac_address: 'aa:11:bb:22:ef', name: 'Differnet Name'} }
      post "/api/v1/families/#{@user.family_id}/devices", query_str.to_json,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""   }
      expect(response.status).to eq(200)
      json = JSON.parse(response.body)
      expect(json["device"]["id"]).to eq(device_id)
    end

    it 'retrieves an existing family device' do
      device = FactoryGirl.create(:device, family: @user.family)
      get "/api/v1/families/#{@user.family_id}/devices/#{device.id}", nil, { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""   }

      json = JSON.parse(response.body)
      expect(response.status).to eq(200)
      expect(json['device']['id']).to eq(device.id)
    end

    it 'can not retrieve another families device' do
      device = FactoryGirl.create(:device)
      get "/api/v1/families/#{device.family_id}/devices/#{device.id}", nil, { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""   }

      json = JSON.parse(response.body)
      expect(response.status).to eq(403)
      expect(json['messages']['error']).to include('You are not authorized to do this.')
    end

    it 'device must belong to the family' do
      device = FactoryGirl.create(:device)
      get "/api/v1/families/#{@user.family_id}/devices/#{device.id}", nil, { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Authorization' => "Token token=\"#{@token}\""   }

      json = JSON.parse(response.body)
      expect(response.status).to eq(404)
      expect(json['messages']['error']).to include('Family or Device not found.')
    end
  end

  it 'allows posting of a device application' do

    payload = '{ "app" : {  "name" : "API Test Icon 5", "uuid" : "com.kudoso.ccsf5", "icon" : { "content-type" : "image/png", "content" : "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\nyquqyhf8+Mf/R9zqMeuAD0OAPjd/TG+uXRcfN64uuXDhouUmisBhKrx1h/Jw\n2BVo/vFY4duK8qmnYH2rFTefDvS6ZuP6v6vDpEoLYtEhdKYsiCoBmrOCUGkY\nAQRiFBM60DIbIRYukGsdUSPnugnkuSbcIp/xXBYsSCgQaAtZ43Pz7Lw2IRrp\nyz704EMrN2zc1M5XhDWEST6xfRwCDHfffffEW2792g9NRqPXxJWJ0nlxRxYB\nRwEpyvnbpQWYYmzD9WeVobYihMX1Cq2DCofNgLn1dgzlzdgwUAmvkqKaMrwP\npPgKo1wgeuF4oAU5uqhw6TqCeC0mkgcYZbXCDfpRQZYm8OpFdn5fQjpTGLh4\nxaU/5xtiBiU+EEX+iU0Q+5Ft2bLTZpYKmRqDrIgTT64wwWSmLVcsCBgymHrg\n37C5x4N0ToHHmqJmziI2lEBSHBtzEFOUvbDHDqFg9xJg7f/KvADBPir7Aqh+\nzml0WZfr0ecy9YhCFCSINyguiDhKg/QHMnSExCR6PGUV9FIfefapZ2fIax8J\n1AcefNyL2tlnn7/6e9+756rIYG9WmK+SMudyiC9Qoqb3ojq5Eb9Y8DaKmR7s\nONBN6ufgcNnR09WO3z7xNNa+/BImbL9RBwYm07BXNwqsKLnR89EjgRYqC3fI\nUX9O4M3HvcvbOjdYiYgC/ZFj9CTFvBiNikI3ZWFdfbUowtHXPgDuf738KARw\nKbo7mX/w4UcP0PfpVotF2ClzonhK9AzzJRPcC69BT/sx+MsqKYdGRCJxDAwO\n4VhbNy749HLce+8/4pEffg2VfWuZs3IRoGEuENnWgeRRl3MBll1YXeRbWFyu\nZXHUvTrAo2JiIvn19/itvHCkT5wLromL3L2r8U+LT1v6HJ/I0zE1meOjmshQ\n8eD+/TdWVFbVFenambnaer+JLq+CMkMc76Sm4uXkaRiIppBJpRFLJNHTMwBP\nWRncpiiSRSu85dX47NQkSjk6R4RKABIghUY6gPyRIx3NYSU4cl80v5FsLjpC\nRwqPJp5Q/epuuC4GNM1H+oYVPiMwmC0uiQMks/Q3I0A4QG/FQrImOtjHRZBm\nHPakCgMRoHH9tAaBMLro4+/e/Br6+gYw0NePI4eP4MDBQ3j9uZ+gdfsf0N66\nG2fPsmKcpQ9Z1aTL6yhrC5V1RHDcUZZX6P+SnWEkcORqyjuv+ZqYQaOYUz4z\n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\n" }  } }'
    timestamp = Time.now.utc.to_i.to_s
    path = "/api/v1/devices/#{@device.id}/apps"
    post path, payload,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Timestamp' => timestamp, 'Signature' => Digest::MD5.hexdigest(path + timestamp + @device.secure_key)  }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)

    expect(json["apps"].last["icon_urls"].count).to eq(4) # should have generated 4 icon urls
  end

  it 'allows posting of a device multiple applications' do

    icon = ' "icon" : { "content-type" : "image/png", "content" : "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\nyquqyhf8+Mf/R9zqMeuAD0OAPjd/TG+uXRcfN64uuXDhouUmisBhKrx1h/Jw\n2BVo/vFY4duK8qmnYH2rFTefDvS6ZuP6v6vDpEoLYtEhdKYsiCoBmrOCUGkY\nAQRiFBM60DIbIRYukGsdUSPnugnkuSbcIp/xXBYsSCgQaAtZ43Pz7Lw2IRrp\nyz704EMrN2zc1M5XhDWEST6xfRwCDHfffffEW2792g9NRqPXxJWJ0nlxRxYB\nRwEpyvnbpQWYYmzD9WeVobYihMX1Cq2DCofNgLn1dgzlzdgwUAmvkqKaMrwP\npPgKo1wgeuF4oAU5uqhw6TqCeC0mkgcYZbXCDfpRQZYm8OpFdn5fQjpTGLh4\nxaU/5xtiBiU+EEX+iU0Q+5Ft2bLTZpYKmRqDrIgTT64wwWSmLVcsCBgymHrg\n37C5x4N0ToHHmqJmziI2lEBSHBtzEFOUvbDHDqFg9xJg7f/KvADBPir7Aqh+\nzml0WZfr0ecy9YhCFCSINyguiDhKg/QHMnSExCR6PGUV9FIfefapZ2fIax8J\n1AcefNyL2tlnn7/6e9+756rIYG9WmK+SMudyiC9Qoqb3ojq5Eb9Y8DaKmR7s\nONBN6ufgcNnR09WO3z7xNNa+/BImbL9RBwYm07BXNwqsKLnR89EjgRYqC3fI\nUX9O4M3HvcvbOjdYiYgC/ZFj9CTFvBiNikI3ZWFdfbUowtHXPgDuf738KARw\nKbo7mX/w4UcP0PfpVotF2ClzonhK9AzzJRPcC69BT/sx+MsqKYdGRCJxDAwO\n4VhbNy749HLce+8/4pEffg2VfWuZs3IRoGEuENnWgeRRl3MBll1YXeRbWFyu\nZXHUvTrAo2JiIvn19/itvHCkT5wLromL3L2r8U+LT1v6HJ/I0zE1meOjmshQ\n8eD+/TdWVFbVFenambnaer+JLq+CMkMc76Sm4uXkaRiIppBJpRFLJNHTMwBP\nWRncpiiSRSu85dX47NQkSjk6R4RKABIghUY6gPyRIx3NYSU4cl80v5FsLjpC\nRwqPJp5Q/epuuC4GNM1H+oYVPiMwmC0uiQMks/Q3I0A4QG/FQrImOtjHRZBm\nHPakCgMRoHH9tAaBMLro4+/e/Br6+gYw0NePI4eP4MDBQ3j9uZ+gdfsf0N66\nG2fPsmKcpQ9Z1aTL6yhrC5V1RHDcUZZX6P+SnWEkcORqyjuv+ZqYQaOYUz4z\n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\n" }'
    apps = ' { "apps" : [ '
    5.times do |idx|
      apps += "{  \"name\" : \"API Test Icon #{idx}\", \"uuid\" : \"com.kudoso.#{idx}\", "
      apps += icon

      if idx < 4
        apps += '}, '
      else
        apps += '}'
      end
    end
    apps += '] }'
    timestamp = Time.now.utc.to_i.to_s
    path = "/api/v1/devices/#{@device.id}/apps"
    post path, apps,  { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'Timestamp' => timestamp, 'Signature' => Digest::MD5.hexdigest(path + timestamp + @device.secure_key)  }
    expect(response.status).to eq(200)
    json = JSON.parse(response.body)
    expect(json["apps"].count).to eq(5)
  end

end