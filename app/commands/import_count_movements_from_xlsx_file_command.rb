module ImportCountMovementsFromXlsxFileCommand
  def self.call(count, files)
    is_metal = count.metal_account?
    expense_items_by_colors = is_metal ? {} : ExpenseItem.where(organization_id: count.organization_id).map{ | expense_item | [ expense_item.color[1..-1], expense_item.id ] }.to_h

    files.each do |f|
      puts "START PARSE #{f} file"

      xlsx = Roo::Spreadsheet.open(f, extension: :xlsx)
      xlsx = Roo::Excelx.new(f, file_warning: :ignore)
      workbook = RubyXL::Parser.parse(f) unless is_metal
      worksheet = workbook[0] unless is_metal
      sheet = xlsx.sheet(0)

      (6..sheet.last_row).each do |row|
        if is_metal
          # Layout 16 colonne: A-H vendite, I-P acquisti
          # A/I=Data, B/J=Causale, C/K=Caratura, D/L=Valore(skip), E/M=Spread(skip), F/N=€/grammo, G/O=Totale(skip), H/P=Grammi
          out_empty = sheet.cell(row, 1).blank? && sheet.cell(row, 2).blank? && sheet.cell(row, 8).blank?
          in_empty = sheet.cell(row, 9).blank? && sheet.cell(row, 10).blank? && sheet.cell(row, 16).blank?
          break if out_empty && in_empty

          movement_type = out_empty ? 'in' : 'out'

          if movement_type == 'out'
            raw_date = sheet.cell(row, 1)
            causal = sheet.cell(row, 2)
            karat_str = sheet.cell(row, 3)
            ppg = sheet.cell(row, 6)
            amount = sheet.cell(row, 8)
          else
            raw_date = sheet.cell(row, 9)
            causal = sheet.cell(row, 10)
            karat_str = sheet.cell(row, 11)
            ppg = sheet.cell(row, 14)
            amount = sheet.cell(row, 16)
          end

          # Parse date
          if raw_date.is_a?(Date) || raw_date.is_a?(DateTime) || raw_date.is_a?(Time)
            emitted_at = raw_date.strftime('%d/%m/%Y')
          else
            emitted_at = raw_date.to_s.gsub('.', '/')
            emitted_at = emitted_at[0...-2] + "20" + emitted_at[-2..-1] if emitted_at.match?(/\/\d{2}$/)
          end

          # Parse amount
          amount = amount.to_s.gsub('€', '').gsub('g', '').gsub('.', '').gsub(',', '.').strip.to_f unless amount.is_a?(Numeric)
          amount = amount * -1 if movement_type == 'out' && amount > 0

          # Parse karat
          karat = karat_str.to_s.gsub('k', '').gsub('K', '').strip.to_f

          # Parse price per gram
          ppg = ppg.to_s.gsub('€', '').gsub('g', '').gsub('.', '').gsub(',', '.').strip.to_f unless ppg.is_a?(Numeric)

          movement_data = {
            count_id: count.id,
            movement_type: movement_type,
            emitted_at: emitted_at,
            causal: causal,
            amount: amount,
            karat: karat,
            price_per_gram_at_transaction: ppg
          }

          Movement.create!(movement_data)
          puts movement_data.to_s

        else
          # Layout 6 colonne: A-C uscite, D-F entrate (codice originale)
          if sheet.cell(row, 1).blank? && sheet.cell(row, 2).blank? && sheet.cell(row, 3).blank? &&
             sheet.cell(row, 4).blank? && sheet.cell(row, 5).blank? && sheet.cell(row, 6).blank?
            break
          end

          movement_type = sheet.cell(row, 1).blank? && sheet.cell(row, 2).blank? && sheet.cell(row, 3).blank? ? 'in' : 'out'
          raw_date = sheet.cell(row, 1) || sheet.cell(row, 4)
          if raw_date.is_a?(Date) || raw_date.is_a?(DateTime) || raw_date.is_a?(Time)
            emitted_at = raw_date.strftime('%d/%m/%Y')
          else
            emitted_at = raw_date.to_s.gsub('.', '/')
            emitted_at = emitted_at[0...-2] + "20" + emitted_at[-2..-1] if emitted_at.match?(/\/\d{2}$/)
          end
          causal = sheet.cell(row, 2) || sheet.cell(row, 5)
          amount = sheet.cell(row, 3) || sheet.cell(row, 6)
          amount = amount.to_s.gsub('€', '').gsub('g', '').gsub('.', '').gsub(',', '.').strip.to_f unless amount.is_a?(Numeric)
          amount = amount * -1 if movement_type == 'out'

          expense_item_id = nil
          if movement_type == 'out'
            ruby_cell = worksheet.sheet_data[row - 1][2]
            cell_style = workbook.stylesheet.cell_xfs[ruby_cell.style_index]
            fill_id = cell_style&.fill_id
            fill_color = workbook.stylesheet.fills[fill_id].pattern_fill&.fg_color&.rgb
            color_hex = fill_color[2..-1]
            expense_item_id = expense_items_by_colors[color_hex.upcase]
          end

          movement_data = {
            count_id: count.id,
            movement_type: movement_type,
            emitted_at: emitted_at,
            causal: causal,
            amount: amount,
            expense_item_id: expense_item_id
          }

          Movement.create!(movement_data)
          puts movement_data.to_s
        end
      end

      puts "END PARSE #{f} file"
    end
  end
end
