module Api
  class Api::MessagesController < ApplicationController
    def index
      @messages = Message.all
      render json: @messages
    end

    def show
      @message = Message.find(params[:id])
      render json: @greeting
    end
  end
end
