include ApplicationHelper

module GetRealTimeGoldPriceCommand
  require "uri"
  require "net/http"

  def self.call(metal = 'XAU', date = nil)
    puts "********************** STARTING GET METAL PRICES ********************** "

    begin
      yesterday = Time.now - 1.day
      date = "#{yesterday.year}#{yesterday.month.to_s.rjust(2, '0')}#{yesterday.day.to_s.rjust(2, '0')}" if date.blank?

      url = URI(MetalPricesParams::METAL_PRICES_URL.gsub(':metal', metal.to_s).gsub(':date', date.to_s))
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request["x-access-token"] = MetalPricesParams::METAL_PRICES_ACCESS_TOKEN

      response = https.request(request)
      if response.code.to_s == '200'
        gold_prices = JSON.parse(response.body)
        puts "gold prices: #{gold_prices}"
      else
        error_message = "An error occours during getting gold_prices:  #{response.code} - #{response.message}"
        puts error_message
        raise error_message
      end
    rescue StandardError => e
      Rails.logger.warn e
      raise e
    end

    puts "*********************** ENDING GET GOLD PRICE *********************** "
  end
end