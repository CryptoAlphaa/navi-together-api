require 'sequel'

module Cryal
    class User_Room < Sequel::Model
        many_to_one :room
        many_to_one :user
        
        def to_json(*args)
            {
                id: id,
                room_id: room_id,
                user_id: user_id,
                active: active
            }.to_json(*args)
        end
    end
end