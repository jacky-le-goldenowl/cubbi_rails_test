module Api
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

      def destroy
        user = User.find(params[:id])
        user.destroy!
      end

      private

      def user_params
        # TODO: move to pundit policy
        params.require(:user).permit(
          :email,
          :first_name,
          :last_name,
          :birthday_date,
          :location
        )
      end
    end
  end
end
