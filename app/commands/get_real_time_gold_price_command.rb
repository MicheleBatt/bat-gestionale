include ApplicationHelper

module GetRealTimeGoldPriceCommand
  require "uri"
  require "net/http"
  include CountsHelper

  def self.call(date = nil)
    puts "********************** STARTING GET METAL PRICES ********************** "

    begin
      yesterday = Time.now - 1.day
      date = "#{yesterday.year}#{yesterday.month.to_s.rjust(2, '0')}#{yesterday.day.to_s.rjust(2, '0')}" if date.blank?

      ALL_METALS.keys.each do |metal|
        url = URI(MetalPricesParams::METAL_PRICES_URL.gsub(':metal', metal.to_s).gsub(':date', date.to_s))
        https = Net::HTTP.new(url.host, url.port)
        https.use_ssl = true

        request = Net::HTTP::Get.new(url)
        request["x-access-token"] = MetalPricesParams::METAL_PRICES_ACCESS_TOKEN

        response = https.request(request)
        if response.code.to_s == '200'
          prices = JSON.parse(response.body)
          prices.keys.filter { | key | key.include?("price_gram_") }.each do | key |
            value = prices[key].to_f.round(2)
            karat = key.split('price_gram_')[1][0..-2].to_f.round(2)
            metal_value = MetalValue.where(metal: metal, karat: karat).first_or_initialize
            metal_value.update!(value: value)
          end
          puts "#{metal} prices: #{prices}"
        else
          error_message = "An error occours during getting #{metal} prices:  #{response.code} - #{response.message}"
          puts error_message
          raise error_message
        end
      end
    rescue StandardError => e
      Rails.logger.warn e
      raise e
    end

    puts "*********************** ENDING GET METAL PRICES *********************** "
  end
end