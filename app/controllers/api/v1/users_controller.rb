module API
  module V1
    class UsersController < BaseController
      def create
        user = User.new(user_params)

        if user.save
          render json: user, status: :ok
        else
          render json: user.errors, status: :unprocessable_entity
        end
      end
    end
  end
end
