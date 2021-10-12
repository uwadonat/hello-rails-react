module Api
  class MessagesController < ApplicationController
    def index
      @messages = Message.order('create_at DESC');
      render json: {status: 'SUCCESS', message:"loaded messages", data:messages,status: :ok}
    end

    def show
      message = Message.find(params[:id])
      render json: {status: 'SUCCESS', message:'Loaded message', data:message, status: :ok}
    end
  end
end