namespace :updateDB do
  desc 'Database Update'

  task :update_db => :environment do
    puts '******************* STARTING UPDATE DB *******************'





    puts "******************* STARTING GET LAST METAL VALUES *******************"

    ((Date.today - 62.days)..(Date.today - 1.days)).to_a.each do | date |
      GetRealTimeMetalsValueCommand.call(['XAU', 'XAG'], date)
    end

    puts "******************** ENDING GET LAST METAL VALUES ********************"





    puts '******************** ENDING UPDATE DB ********************'
  end






  desc "Check any invalid data records"
  task :invalid_records => :environment do
    puts "\n** STARTING CHECK RECORDS VALIDATIONS IN #{Rails.env.upcase} ENVIRONMENT **\n"

    puts "INVALID COUNTS IDS: #{Count.all.select(&:invalid?).pluck(:id).to_s}"

    puts "INVALID DEADLINES IDS: #{Deadline.all.select(&:invalid?).pluck(:id).to_s}"

    puts "INVALID EXPENSE_ITEMS IDS: #{ExpenseItem.all.select(&:invalid?).pluck(:id).to_s}"

    puts "INVALID MEMBERSHIPS IDS: #{Membership.all.select(&:invalid?).pluck(:id).to_s}"

    puts "INVALID METAL_VALUES IDS: #{MetalValue.all.select(&:invalid?).pluck(:id).to_s}"

    puts "INVALID MOVEMENTS IDS: #{Movement.all.select(&:invalid?).pluck(:id).to_s}"

    puts "INVALID ORGANIZATIONS IDS: #{Organization.all.select(&:invalid?).pluck(:id).to_s}"

    puts "INVALID USERS IDS: #{User.all.select(&:invalid?).pluck(:id).to_s}"

    puts "\n*** ENDING CHECK RECORDS VALIDATIONS IN #{Rails.env.upcase} ENVIRONMENT ***\n"
  end
end