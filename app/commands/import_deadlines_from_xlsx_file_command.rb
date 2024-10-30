include ApplicationHelper

module ImportDeadlinesFromXlsxFileCommand
  def self.call(organization, files)
    files.each do |f|
      puts "START PARSE #{f} file"

      xlsx = Roo::Spreadsheet.open(f, extension: :xlsx)
      xlsx = Roo::Excelx.new(f, file_warning: :ignore)
      sheet = xlsx.sheet(0)

      current_year = nil
      (4..sheet.last_row).each do |row|
        current_year = sheet.cell(row, 1) || current_year
        description = sheet.cell(row, 3)
        date = sheet.cell(row, 2).to_s.strip.split(' ')
        day = date[0]
        month = ITALIAN_MONTHS.key(date[1].downcase.capitalize)
        expired_at = "#{day}/#{month}/#{current_year}"

        deadline = {
          description: description,
          expired_at: expired_at
        }

        Deadline.create!(
          organization_id: organization.id,
          description: description,
          expired_at: expired_at
        )

        puts deadline.to_s
      end

      puts "END PARSE #{f} file"
    end
  end
end