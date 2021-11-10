# encoding: utf-8
require 'line/bot'
require 'active_support/all'
require 'rest-client'
require 'nokogiri'
require 'open-uri'

class PttController < ApplicationController
  protect_from_forgery with: :null_session

  def request_headers
    render plain: request.headers.to_h.reject{ |key, value|
      key.include? '.'
    }.map{
      |key, value| "#{key}: #{value}"
    }.sort.join("\n")
  end

  def request_body
    render plain: request.body
  end

  def response_headers
    response.headers['5566'] = 'qq'
    render plain: response.headers.to_h.map{
      |key, value| "#{key}: #{value}"
    }.sort.join("\n")
  end

  def show_response_body
    puts "===這是設定前的response.body:#{response.body}==="
    render plain: "0816065"
    puts "===這是設定後的response.body:#{response.body}==="
  end

  def sent_request
    uri = URI('http://localhost:3000/ptt/eat')
    http = Net::HTTP.new(uri.host, uri.port)
    http_request = Net::HTTP::Get.new(uri)
    http_response = http.request(http_request)

    render plain: JSON.pretty_generate({
      request_class: request.class,
      response_class: response.class,
      http_request_class: http_request.class,
      http_response_class: http_response.class
    })
  end

  def received_text
    msg = params['events'] && params['events'][0] && params['events'][0]['message']
    msg['text'].strip unless msg.nil?
  end

  def webhook

    if params['events'][0]['message']['type'] == "sticker"
      buttom_template()
      head :ok
      return
    end

    reply_img = get_weather(received_text)

    unless reply_img.nil?
      reply_img_to_line(reply_img)
      head :ok
      return
    end

    message = func(user_id, received_text)
    save_to_received(user_id,received_text)
    # 傳送訊息
    reply_to_line(message) unless message.nil?
    # 回應 200
    head :ok
  end

  def line
    # Line Bot API 物件初始化
    return @line unless @line.nil?
    @line = Line::Bot::Client.new { |config|
      config.channel_secret = '7342cdffd54e4db6dba89eb09e67f7e1'
      config.channel_token = '4zvVeq9W+BCZy/erKQ3S+1UHObFz85Rl8z28mciczBGAdN9tlEPVrwJ0aU12QVH/IUuU2rNXoEl6Dv0bcVHwWUvnre8bzqjW417xcXl4Boh1ElaDRQxdqDbIdW3HKsnBVI6luUiVvvL8i9nu3zfWMgdB04t89/1O/w1cDnyilFU='
    }
  end

  def user_id
    source = params['events'][0]['source']
    source['userId']
  end

  def save_to_received(user_id, received_text)
    return if received_text.nil?
    Received.create(user_id: user_id, text: received_text)
  end

  def func(user_id,received_text)
    return "請輸入您想查詢的關鍵字" if received_text == "search" || received_text == "findingbuyer"
    return "請輸入您要訂閱的關鍵字" if received_text == "subscribe"
    return list_subscribe() if received_text == "unsubscribe"

    recent_received_text = Received.where(user_id: user_id).last&.text

    return get_search(received_text) if recent_received_text == "search"
    return find_buyer(received_text) if recent_received_text == "findingbuyer"
    return add_subscribe(received_text) if recent_received_text == "subscribe"
    return dele_subscribe(received_text) if recent_received_text == "unsubscribe"
    return nil
  end

  def reply_to_line(msg)
    reply_token = params['events'][0]['replyToken']
    message = {
      type: 'text',
      text: msg
    }
    line.reply_message(reply_token,message)
  end

  def buttom_template
    reply_token = params['events'][0]['replyToken']
    button = {
      type: 'template',
      altText: '功能表',
      template: {
        type: 'buttons',
        thumbnailImageUrl: "https://i.imgur.com/DBo7rvh.png#".force_encoding('UTF-8'),
        imageAspectRatio: "rectangle",
        imageSize: "cover",
        imageBackgroundColor: '#A0A0A0',
        title: "我可以做下面這些事" ,
        text: "請選擇您所要的功能",
        actions: [
          {
            type: 'message',
            label: '查詢商品',
            text: 'search'
          },
          {
            type: 'message',
            label: '訂閱關鍵字',
            text: 'subscribe'
          },
          {
            type: 'message',
            label: '找找有沒有人要買',
            text: 'findingbuyer'
          },
          {
            type: 'message',
            label: '取消訂閱關鍵字',
            text: 'unsubscribe'
          }
        ]
      }
    }
    line.reply_message(reply_token,button)
  end

  def reply_img_to_line(reply_img)
    return nil if reply_img.nil?

    reply_token = params['events'][0]['replyToken']

    msg = {
      type: 'image',
      originalContentUrl: reply_img.force_encoding('UTF-8'),
      previewImageUrl: reply_img.force_encoding('UTF-8')
    }

    line.reply_message(reply_token, msg)
  end


  def get_weather(msg)
    return nil unless msg.include?("天氣")

    uri = URI('https://www.cwb.gov.tw/V8/C/W/OBS_Radar.html')
    response = Net::HTTP.get(uri).force_encoding('UTF-8')
    start_index = response.index('src') +5
    end_index = response.index('alt="雷達回波"') -4
    'https://www.cwb.gov.tw' + response[start_index..end_index]
    #reply_to_line(u)
  end

  def get_search(msg)
    url = 'https://www.ptt.cc/bbs/MacShop/index.html'

    sell = []
    search = ""

    count=0
    while count<6
      page_now = Nokogiri::HTML(URI.open( url ),nil,"utf-8")
      #prev_url = "https://www.ptt.cc"
      page_now.xpath('//a').each do |i|
        i = i.to_s.sub(/href=\"/,"https://www.ptt.cc").sub("</a>","").sub("<a ","").sub("\">"," ")
        url = i[i.index('https')..i.index('html')+3] if i.include? "上頁"

        sell << i if i.include? "販售"
      end
      count += 1
    end

    sell.each do |s|
      search += s[s.index("https")..s.index("html")+3]+ " \n " if s.downcase.include? msg.downcase
    end

    return "很抱歉 找不到搜尋的目標" if search == ""
    return search
  end

  def find_buyer(msg)
    url = 'https://www.ptt.cc/bbs/MacShop/index.html'

    buy = []
    search = ""

    count=0
    while count<10
      page_now = Nokogiri::HTML(URI.open( url ),nil,"utf-8")
      #prev_url = "https://www.ptt.cc"
      page_now.xpath('//a').each do |i|
        i = i.to_s.sub(/href=\"/,"https://www.ptt.cc").sub("</a>","").sub("<a ","").sub("\">"," ")
        url = i[i.index('https')..i.index('html')+3] if i.include? "上頁"

        buy << i if i.include? "收購"
      end
      count += 1
    end

    buy.each do |s|
      search += s[s.index("https")..s.index("html")+3]+ " \n " if s.downcase.include? msg.downcase
    end

    return "很抱歉 找不到搜尋的目標" if search == ""
    return search
  end

  def add_subscribe(msg)
    return "已經訂閱過此項目囉" unless Subscribe.find_by(user_id: user_id, item: msg).nil?
    Subscribe.create(user_id: user_id,item: msg)
    p Subscribe.all
    p("已成功訂閱: "+ msg )
    return "已成功訂閱: "+ msg
  end

  def dele_subscribe(msg)
    return "找不到此訂閱項目" if Subscribe.find_by(user_id: user_id, item: msg).nil?
    Subscribe.where(user_id: user_id, item: msg).delete_all
    p Subscribe.all
    return "已刪除訂閱項目: "+ msg
  end

  def list_subscribe
    p Subscribe.all
    items = Subscribe.where(user_id: user_id).all
    sub = ""

    items.pluck(:item).each do |i|
      sub += i.to_s + "\n"
    end

    return "目前無訂閱項目" if sub == ""
    return "您目前的訂閱項目:\n\n" + sub + "\n請輸入您要刪除的項目"
  end

end
