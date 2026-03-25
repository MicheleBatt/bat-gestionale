include ApplicationHelper

module GetRealTimeMetalsValueCommand
  require "uri"
  require "net/http"
  include CountsHelper

  def self.call(metals = ALL_METALS.keys, date = Date.today - 1.day)
    puts "********************** STARTING GET METAL VALUES ********************** "

    date = "#{date.year}#{date.month.to_s.rjust(2, '0')}#{date.day.to_s.rjust(2, '0')}"
    recorded_date = Date.parse("#{date[0..3]}-#{date[4..5]}-#{date[6..7]}")

    metals.each do |metal|
      begin
        if MetalValue.where(metal: metal, recorded_at: recorded_date).blank?
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
              metal_value = MetalValue.where(metal: metal, karat: karat, recorded_at: recorded_date).first_or_initialize
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
        Rails.logger.warn "Failed to fetch #{metal} values: #{e}"
      end
    end

    Movement.joins(:count).where(counts: { count_type: metals.map { | metal_type | "#{metal_type.downcase}_investment_account" } }).each { | m | m.save! }


    puts "*********************** ENDING GET METAL VALUES *********************** "
  end
end