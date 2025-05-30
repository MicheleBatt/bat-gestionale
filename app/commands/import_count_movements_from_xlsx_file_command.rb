module ImportCountMovementsFromXlsxFileCommand
  def self.call(count, files, expense_items_by_colors)
    files.each do |f|
      puts "START PARSE #{f} file"

      xlsx = Roo::Spreadsheet.open(f, extension: :xlsx)
      xlsx = Roo::Excelx.new(f, file_warning: :ignore)
      workbook = RubyXL::Parser.parse(f)
      worksheet = workbook[0]
      sheet = xlsx.sheet(0)

      (6..sheet.last_row).each do |row|
        if sheet.cell(row, 1).blank? && sheet.cell(row, 2).blank? && sheet.cell(row, 3).blank? &&
           sheet.cell(row, 4).blank? && sheet.cell(row, 5).blank? && sheet.cell(row, 6).blank?
          break
        end
        movement_type = sheet.cell(row, 1).blank? && sheet.cell(row, 2).blank? && sheet.cell(row, 3).blank? ? 'in' : 'out'
        emitted_at = (sheet.cell(row, 1) || sheet.cell(row, 4)).gsub('.', '/')
        emitted_at = emitted_at[0...-2] + "20" + emitted_at[-2..-1]
        causal = sheet.cell(row, 2) || sheet.cell(row, 5)
        amount = sheet.cell(row, 3) || sheet.cell(row, 6)
        amount = amount * -1 if movement_type == 'out'

        if movement_type == 'out'
          ruby_cell = worksheet.sheet_data[row - 1][2]
          cell_style = workbook.stylesheet.cell_xfs[ruby_cell.style_index]
          fill_id = cell_style&.fill_id
          fill_color = workbook.stylesheet.fills[fill_id].pattern_fill&.fg_color&.rgb
          puts "fill_color: #{fill_color}"
          color_hex = fill_color[2..-1]
          expense_item_id = expense_items_by_colors[color_hex.upcase]
        end

        movement = {
          movement_type: movement_type,
          emitted_at: emitted_at,
          causal: causal,
          amount: amount,
          expense_item_id: expense_item_id,
          color_hex: color_hex
        }

        Movement.create!(
          count_id: count.id,
          movement_type: movement_type,
          emitted_at: emitted_at,
          causal: causal,
          amount: amount,
          expense_item_id: expense_item_id
        )

        puts movement.to_s
      end

      puts "END PARSE #{f} file"
    end
  end
end