require "net/http"
require "uri"
require "json" 

class TelegramBot

  TELEGRAM_METHODS = %w(
    getMe sendMessage forwardMessage sendPhoto sendAudio sendDocument sendSticker
    sendVideo sendVoice sendLocation sendChatAction getUserProfilePhotos getUpdates
    setWebhook answerInlineQuery
  ).freeze

  def initialize(token)
    @token = token
  end
  
  def method_missing(method_name, *args, &block)
    telegram_method = method_name.to_s
    TELEGRAM_METHODS.include?(telegram_method) ? call(telegram_method, *args) : super
  end
  
  def call(method_name, params = {})
    uri = URI.parse(bot_url << method_name)
    puts uri.to_s
    puts params.to_s
    response = Net::HTTP.post_form(uri, params)
    
    return JSON.parse(response.body).to_s
  end

  private
  
  def bot_url
    "https://api.telegram.org/bot#{@token}/"
  end
  
  def send_message (chat_id, text = "", web_preview = true, reply_id = nil, reply_markup = nil)
    if chat_id.present?
      uri = URI.parse("https://api.telegram.org/bot#{ENV["TELEGRAM_BOT_API_KEY"]}/sendMessage")
      response = Net::HTTP.post_form(uri,
        {
          :chat_id => chat_id,
          :text => text,
          :disable_web_page_preview => (not web_preview),
          :reply_to_message_id => reply_id,
          :reply_markup => reply_markup
        })
      
      return JSON.parse(response.body)["ok"]
    else
      return false
    end
  end
  
  def repair_webhook
    logger.info "Starting Repair"
    # Clear webhook so that getUpdates can be used
    uri = URI.parse("https://api.telegram.org/bot#{ENV["TELEGRAM_BOT_API_KEY"]}/setWebhook")
    Net::HTTP.post_form(uri,{})
    # Mark all messages as read
    uri = URI.parse("https://api.telegram.org/bot#{ENV["TELEGRAM_BOT_API_KEY"]}/getUpdates")
    Net::HTTP.post_form(uri,{
      :offset => 2147483647
    })
    # Reconfigure webhook
    logger.info "- Webhook to #{telegram_index_url}"
    uri = URI.parse("https://api.telegram.org/bot#{ENV["TELEGRAM_BOT_API_KEY"]}/setWebhook")
    Net::HTTP.post_form(uri,{
      :url => telegram_index_url 
    })
    Rails.cache.delete('bot_command')
    render :json => {:ok => true}
  end
end
