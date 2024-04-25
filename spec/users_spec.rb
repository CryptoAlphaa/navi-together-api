# This spec file is used to test the user model
# We want to test the API to properly interact with the user model
# We will test the GET and POST routes for the user model

# frozen_string_literal: true

require_relative 'init_spec'

describe 'Test User Model' do # rubocop:disable Metrics/BlockLength
  before do
    clear_db
    load_seed

    # fill the user table with the first seed
    app.DB[:users].insert(seed_data[:users].first)
  end

  describe 'HAPPY: Test GET' do
    it 'should get all users' do
      get '/users'
      _(last_response.status).must_equal 200
      users = JSON.parse(last_response.body)
      _(users.length).must_equal 1
    end

    it 'should get a single user' do
      user_id = seed_data[:user_id].first['id']
      get "/users/#{user_id}"
      _(last_response.status).must_equal 200
      user = JSON.parse(last_response.body)
      _(user['id']).must_equal user_id
    end
  end

  describe 'SAD: Test GET' do
    it 'should return 404 if user is not found' do
      get '/users/100'
      _(last_response.status).must_equal 404
    end
  end

  describe 'HAPPY Test POST' do
    it 'should create a new user' do
      # use the second seed to create a new user
      post '/users', seed_data[:users][1].to_json
      _(last_response.status).must_equal 201
      user = JSON.parse(last_response.body)
      _(user['id']).wont_be_nil
    end
  end

  describe 'SAD: Test POST' do
    it 'should return 400 if data is invalid' do
      post '/users', {}.to_json
      _(last_response.status).must_equal 400
    end
  end
end