class ConversationsController < ApplicationController
  def create
    @conversation = Conversation.find(params[:conversation_id])
    @message = @conversation.messages.build(message_params)
    if @message.save
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to conversation_path(@conversation) }
      end
    else
      render :new
    end
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
