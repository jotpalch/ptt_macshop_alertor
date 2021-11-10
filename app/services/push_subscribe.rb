require 'line/bot'
require 'nokogiri'
require 'open-uri'
require 'rss'

class PushSubscribe

  def line
    # Line Bot API 物件初始化
    return @line unless @line.nil?
    @line = Line::Bot::Client.new { |config|
      config.channel_secret = '7342cdffd54e4db6dba89eb09e67f7e1'
      config.channel_token = '4zvVeq9W+BCZy/erKQ3S+1UHObFz85Rl8z28mciczBGAdN9tlEPVrwJ0aU12QVH/IUuU2rNXoEl6Dv0bcVHwWUvnre8bzqjW417xcXl4Boh1ElaDRQxdqDbIdW3HKsnBVI6luUiVvvL8i9nu3zfWMgdB04t89/1O/w1cDnyilFU='
    }
  end

  def push
      #Subscribe.create(user_id: "Ube77819773e41e9b2754d0bc429dafb9",item: "iphone")
      data = Subscribe.all.map { |i| [i.user_id,i.item] }
      data.each do |user_id, items|
        content = search(items)
        next if content.nil?
        msg = {
          type: "text",
          text: "[訂閱內容_#{items}]\n\n" + content
        }
        line.push_message(user_id,msg)
      end
  end

  def search(msg)
    output = ""
    url = 'http://rss.ptt.cc/MacShop.xml'
    URI.open(url) do |rss|
      feed = RSS::Parser.parse(rss)
      feed.items.each do |item|
        title = item.title.content.to_s
        link = item.link.href.to_s
        time = Time.now - item.published.content.to_time
        break if time>3600
        output += title + "\n" + link + "\n" if( title.downcase.include?(msg.downcase) && title.include?("販售") )
      end
    end

    return output unless output==""
    return nil
  end


end
