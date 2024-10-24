

namespace :initDB do
  desc 'Database Initialization'

  task :init_db => :environment do
    if Rails.env != 'test'
      puts 'Are you sure you want to re-initialize the database? [y/n]'
      response = STDIN.gets.chomp
    end

    if Rails.env.test? || response.downcase == 'y'
      # Svuoto il db
      Deadline.destroy_all
      Movement.destroy_all
      ExpenseItem.destroy_all
      Count.destroy_all


      ExpenseItem.where(description: 'Spese per Bollette', color: 'FFC000').first_or_create!
      ExpenseItem.where(description: 'Spese per Acquisti', color: 'FF99FF').first_or_create!
      ExpenseItem.where(description: 'Spese per Pasti fuori', color: 'F4B183').first_or_create!
      ExpenseItem.where(description: 'Spese per Cibo', color: '92D050').first_or_create!
      ExpenseItem.where(description: 'Spese di Lavoro', color: 'B4C7E7').first_or_create!
      ExpenseItem.where(description: 'Spese per Abbonamenti', color: 'BFBFBF').first_or_create!
      ExpenseItem.where(description: 'Spese per Trasporti', color: '7030A0').first_or_create!
      ExpenseItem.where(description: 'Spese per Vaganze / Gite / Svaghi', color: 'A9D18E').first_or_create!
      ExpenseItem.where(description: 'Spese Sanitare', color: '00B0F0').first_or_create!
      ExpenseItem.where(description: 'Spese per Bimbe', color: 'FFD966').first_or_create!
      ExpenseItem.where(description: 'Spese per Lavori sulla casa', color: 'C55A11').first_or_create!
      ExpenseItem.where(description: 'Spese Varie', color: 'FFFFFF').first_or_create!


      # Creo alcuni record del db
      Count.where(
        name: 'Conto cointestato BPER per le spese di famiglia',
        description: 'Conto di famiglia per le spese di famiglia',
        initial_amount: 546.5,
        ordering_number: 1
      ).first_or_create!

      Count.where(
        name: 'Conto cointestato INTESA SAN PAOLO per i risparmi di famiglia',
        description: 'Conto di famiglia per i risparmi di famiglia',
        initial_amount: 0,
        ordering_number: 2
      ).first_or_create!
    end
  end





  task import_movements_data: :environment do
    file_paths = []

    directory_path = 'private/import-xlsx/movements'

    if Dir.exist?(directory_path)
      # Utilizzo Dir.glob per trovare tutti i file ricorsivamente
      file_paths = Dir.glob(File.join(directory_path, '**', '*')).select { |path| File.file?(path) }
    else
      puts "La directory non esiste."
    end

    file_paths = file_paths.filter{ | file | file.include?('xlsx') && !file.to_s.downcase.include?('andamento') }

    expense_items_by_colors = ExpenseItem.all.map{ | expense_item | [ expense_item.color[1..-1], expense_item.id ] }.to_h
    ImportCountMovementsFromXlsxFileCommand.call(Count.first, file_paths, expense_items_by_colors)
  end
end