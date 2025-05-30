

namespace :updateDB do
  desc 'Database Update'
  # Importer da file excel dei dati dei movimenti di uno specifico conto corrente
  task update_db: :environment do
    file_paths = []

    directory_path = 'private/import-xlsx/movements'

    if Dir.exist?(directory_path)
      # Utilizzo Dir.glob per trovare tutti i file ricorsivamente
      file_paths = Dir.glob(File.join(directory_path, '**', '*')).select { |path| File.file?(path) }
    else
      puts "La directory private/import-xlsx/movements non esiste!!!"
    end

    file_paths = file_paths.filter{ | file | file.include?('xlsx') && !file.to_s.downcase.include?('andamento') }

    expense_items_by_colors = ExpenseItem.all.map{ | expense_item | [ expense_item.color[1..-1], expense_item.id ] }.to_h
    ImportCountMovementsFromXlsxFileCommand.call(Count.find(1), file_paths, expense_items_by_colors)
  end
end