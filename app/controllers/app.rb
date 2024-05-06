# frozen_string_literal: true

require 'sequel'
require 'roda'
require 'json'

module Cryal
  # Class for designing the API
  class Api < Roda # rubocop:disable Metrics/ClassLength
    plugin :environments
    plugin :halt
    plugin :json

    route do |routing| # rubocop:disable Metrics/BlockLength
      response['Content-Type'] = 'application/json'

      routing.root do
        response.status = 200
        { message: 'Welcome to Cryal APIs' }.to_json
      end

      routing.on 'api/v1' do # rubocop:disable Metrics/BlockLength
        routing.on 'users' do # rubocop:disable Metrics/BlockLength
          routing.on String do |user_id| # rubocop:disable Metrics/BlockLength
            routing.is do
              # GET /api/v1/users/[user_id] DONE
              routing.get do
                output = Cryal::UserService::User::FetchOne.call(routing, user_id)
                response.status = 200
                output.to_json
              end
            end

            routing.on 'locations' do
              # GET /api/v1/users/[user_id]/locations DONEE
              routing.get do
                output = Cryal::UserService::Location::FetchAll.call(routing, user_id)
                response.status = 200
                output.to_json
                # user_fetch_locations(routing, user_id)
              end

              # POST /api/v1/users/[user_id]/locations DONEE
              routing.post do
                json = JSON.parse(routing.body.read)
                output = Cryal::UserService::Location::Create.call(routing, json, user_id)
                
                response.status = 201
                { message: 'Location saved', data: output }.to_json
              rescue StandardError => e
                log_and_handle_error(routing, json, e)
                # user_create_location(routing, user_id)
              end
            end

            # GET /api/v1/users/[user_id]/rooms DONEE
            routing.on 'rooms' do
              routing.get do
                output = Cryal::UserService::Room::FetchOne.call(routing, user_id)
                not_found(routing, 'DB Error') if output.nil?
                response.status = 200
                output.to_json
                # user_fetch_rooms(routing, user_id)
              end
            end

            # POST /api/v1/users/[user_id]/createroom DONEE
            routing.on 'createroom' do
              routing.post do
                # user_create_room(routing, user_id)
                json = JSON.parse(routing.body.read)
                output = Cryal::UserService::Room::Create.call(routing, json, user_id)
                response.status = 201
                { message: 'Room created', data: output }.to_json
              rescue StandardError => e
                log_and_handle_error(routing, json, e)
                # Cryal::UserService::Room::Join.call(routing, user_id)
              end
            end

            # POST /api/v1/users/[user_id]/joinroom DONEE
            routing.on 'joinroom' do
              routing.post do
                # user_join_room(routing, user_id)
                json = JSON.parse(routing.body.read)
                output = Cryal::UserService::Room::Join.call(routing, json, user_id)
                response.status = 201
                { message: 'Room Join Successfully', data: output }.to_json
              rescue StandardError => e
                log_and_handle_error(routing, json, e)
              end
            end

            # POST /api/v1/users/[user_id]/plans
            routing.on 'plans' do # rubocop:disable Metrics/BlockLength
              # POST /api/v1/users/[user_id]/plans/create_plan DONEE
              routing.on 'create_plan' do
                routing.post do
                  # user_create_plan(routing, user_id)
                  json = JSON.parse(routing.body.read)
                  output = Cryal::UserService::Plans::Create.call(routing, json, user_id)
                  response.status = 201
                  { message: 'Plan saved', data: output }.to_json
                rescue StandardError => e
                  log_and_handle_error(routing, json, e)
                end
              end

              # GET /api/v1/users/[user_id]/plans/fetch DONEE
              routing.on 'fetch' do
                routing.get do
                  # user_fetch_plans(routing, user_id)
                  output = Cryal::UserService::Plans::FetchOne.call(routing, user_id)
                  response.status = 200
                  output.to_json
                end
              end

              # api/v1/users/[user_id]/plans/[plan_id]
              routing.on String do |plan_id|
                routing.on 'waypoints' do
                  # POST /api/v1/users/[user_id]/plans/[plan_id]/waypoints DONEE
                  routing.post do
                    # user_create_waypoint(routing, user_id, plan_id)
                    json = JSON.parse(routing.body.read)
                    output = Cryal::UserService::Waypoint::Create.call(routing, json, user_id, plan_id)
                    response.status = 201
                    { message: 'Waypoint saved', data: output }.to_json
                  rescue StandardError => e
                    log_and_handle_error(routing, json, e)
                  end

                  # GET /api/v1/users/[user_id]/plans/[plan_id]/waypoints DONE
                  routing.get do
                    # user_fetch_waypoints(routing, user_id, plan_id)
                    output = Cryal::UserService::Waypoint::FetchOne.call(routing, user_id, plan_id)
                    response.status = 200
                    output.to_json
                  end
                end
              end
            end
          end

          # GET /api/v1/users DONEE
          routing.get do
            output = Cryal::GlobalActions::User::FetchAll.call(routing)
            response.status = 200
            output.to_json
          end

          # POST /api/v1/users DONEE
          routing.post do
            json = JSON.parse(routing.body.read)
            output = Cryal::GlobalActions::User::Create.call(json)

            response.status = 201
            { message: 'User saved', data: output }.to_json
          rescue StandardError => e
            log_and_handle_error(routing, json, e)
          end

        end
        routing.on 'rooms' do
          routing.on String do |room_id|
            routing.is do
              # GET /api/v1/rooms/[room_id]
              routing.get do
                output = Cryal::GlobalActions::Room::FetchOne.call(routing, room_id)
                response.status = 200
                output.to_json
                # global_fetch_room(routing, room_id)
              end
            end
          end
          # GET /api/v1/rooms DONEE
          routing.get do
            output = Cryal::GlobalActions::Room::FetchAll.call(routing)
            response.status = 200
            output.to_json
            # global_fetch_room_all(routing)
          end
        end

        routing.on 'userrooms' do
          # GET /api/v1/userrooms DONE
          routing.get do
            output = Cryal::GlobalActions::UserRooms::FetchAll.call(routing)
            response.status = 200
            output.to_json
          end
        end
      end
    end

    # Naming Convention [Route]_[Task]_[Object]_[AdditionalInfo]

    # def user_fetch_user(routing, user_id)
    #   output = User.first(user_id:)
    #   not_found(routing, 'User not found') if output.nil?
    #   response.status = 200
    #   output.to_json
    # end

    # def user_fetch_locations(routing, user_id)
    #   output = User.first(user_id:)
    #   not_found(routing, 'User not found') if output.nil?
    #   locations = output.locations
    #   response.status = 200
    #   locations.to_json
    # end

    # def user_create_location(routing, user_id)
    #   user = User.first(user_id:)
    #   not_found(routing, 'User not found') if user.nil?
    #   location = JSON.parse(routing.body.read)
    #   location = user.add_location(location)
    #   response.status = 201
    #   { message: 'Location saved', data: location }.to_json
    # rescue StandardError => e
    #   log_and_handle_error(routing, location, e)
    # end

    # # TODO : Fix model first
    # def user_fetch_rooms(routing, user_id)
    #   output = { data: User.first(user_id:).rooms }
    #   not_found(routing, 'DB Error') if output.nil?
    #   response.status = 200
    #   output.to_json
    # end

    # def user_create_room(routing, user_id)
    #   user = User.first(user_id:)
    #   not_found(routing, 'User not found') if user.nil?
    #   room = JSON.parse(routing.body.read)
    #   room = user.add_room(room)
    #   response.status = 201
    #   { message: 'Room saved', data: room }.to_json
    # rescue StandardError => e
    #   log_and_handle_error(routing, room, e)
    # end

    # def user_join_room(routing, user_id)
    #   user = User.first(user_id:)
    #   not_found(routing, 'User not found') if user.nil?
    #   user_room = JSON.parse(routing.body.read)
    #   user_room = user.add_user_room(user_room)
    #   response.status = 201
    #   { message: 'Room Join Successfully', data: user_room }.to_json
    # rescue StandardError => e
    #   log_and_handle_error(routing, user_room, e)
    # end

    # def user_create_plan(routing, user_id) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    #   user = User.first(user_id:)
    #   not_found(routing, 'User not found') if user.nil?
    #   plan = JSON.parse(routing.body.read)
    #   room = Room.first(room_name: plan['room_name'])
    #   not_found(routing, 'Room not found') if room.nil?
    #   user_room = User_Room.first(user_id: user.user_id, room_id: room.room_id)
    #   not_found(routing, 'User not in the room') if user_room.nil?
    #   plan.delete('room_name')
    #   final_plan = room.add_plan(plan)
    #   response.status = 201
    #   { message: 'Plan saved', data: final_plan }.to_json
    # rescue StandardError => e
    #   log_and_handle_error(routing, plan, e)
    # end

    # def user_fetch_plans(routing, user_id) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    #   user = User.first(user_id:)
    #   not_found(routing, 'User not found') if user.nil?
    #   search = routing.params['room_name']
    #   room = Room.first(room_name: search)
    #   not_found(routing, 'Room not found') if room.nil?
    #   user_room = User_Room.first(user_id: user.user_id, room_id: room.room_id)
    #   not_found(routing, 'User not in the room') if user_room.nil?
    #   all_plans = room.plans
    #   # Extract only the plan_name and plan_description
    #   output = []
    #   all_plans.each do |plan|
    #     output.push(plan.to_json)
    #   end
    #   response.status = 200
    #   output.to_json
    # end

    # def user_create_waypoint(routing, user_id, plan_id) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    #   user = User.first(user_id:)
    #   not_found(routing, 'User not found') if user.nil?
    #   plan = Plan.first(plan_id:)
    #   not_found(routing, 'Plan not found') if plan.nil?
    #   waypoint = JSON.parse(routing.body.read)
    #   last_waypoint_number = Waypoint.where(plan_id: plan.plan_id).max(:waypoint_number) || 0
    #   new_waypoint_number = last_waypoint_number + 1
    #   # delete waypoint number field if it exists
    #   waypoint.delete('waypoint_number')
    #   waypoint[:waypoint_number] = new_waypoint_number
    #   final_waypoint = plan.add_waypoint(waypoint)

    #   response.status = 201
    #   { message: 'Waypoint saved', data: final_waypoint }.to_json
    # rescue StandardError => e
    #   log_and_handle_error(routing, waypoint, e)
    # end

    # def user_fetch_waypoints(routing, user_id, plan_id)
    #   user = User.first(user_id:)
    #   not_found(routing, 'User not found') if user.nil?
    #   plan = Plan.first(plan_id:)
    #   not_found(routing, 'Plan not found') if plan.nil?
    #   waypoints = plan.waypoints
    #   response.status = 200
    #   waypoints.to_json
    # end

    # def global_create_user(routing)
    #   user = JSON.parse(routing.body.read)
    #   final_user = User.new(user)
    #   final_user.save
    #   response.status = 201
    #   { message: 'User saved', data: final_user }.to_json
    # rescue StandardError => e
    #   log_and_handle_error(routing, user, e)
    # end

    # def global_fetch_users(_routing)
    #   output = { data: User.all }
    #   output.to_json
    # end

    # def global_fetch_room(routing, room_id)
    #   output = Room.first(room_id:)
    #   not_found(routing, 'Room not found') if output.nil?
    #   response.status = 200
    #   output.to_json
    # end

    # def global_fetch_room_all(_routing)
    #   output = { data: Room.all }
    #   output.to_json
    # end

    # def global_fetch_userrooms(_routing)
    #   output = { data: User_Room.all }
    #   output.to_json
    # end
    
    def not_found(routing, message)
      routing.halt 404, { message: }.to_json
    end
    
    def log_and_handle_error(routing, json, err)
      if err.is_a?(Sequel::MassAssignmentRestriction)
        Api.logger.warn "Mass Assignment: #{json.keys}"
        routing.halt 400, { message: 'Mass Assignment Error' }.to_json
      else
        Api.logger.error "Error: #{err.message}"
        routing.halt 500, { message: 'Internal Server Error' }.to_json
      end
    end
  end #end class

  def log_and_handle_error(routing, json, err)
    if err.is_a?(Sequel::MassAssignmentRestriction)
      Api.logger.warn "Mass Assignment: #{json.keys}"
      routing.halt 400, { message: 'Mass Assignment Error' }.to_json
    else
      Api.logger.error "Error: #{err.message}"
      routing.halt 500, { message: 'Internal Server Error' }.to_json
    end
  end

  def not_found(routing, message)
    routing.halt 404, { message: }.to_json
  end
end # end module