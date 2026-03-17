

namespace :initDB do
  desc 'Database Initialization'

  # Script che svuota il db e lo ri-popola con una struttura vergine
  task :init_db => :environment do
    if Rails.env != 'test'
      puts 'Are you sure you want to re-initialize the database? [y/n]'
      response = STDIN.gets.chomp
    end

    if Rails.env.test? || response.downcase == 'y'
      # Svuoto il db
      MetalValue.delete_all
      Deadline.delete_all
      Movement.delete_all
      ExpenseItem.delete_all
      Count.delete_all


      # Salvo il valore corrente dell'oro e dell'argento
      GetRealTimeGoldPriceCommand.call


      # Creo la prima organizzazione
      first_organization = Organization.where(name: 'Famiglia Battistelli').first_or_create!


      # Creo le voci di spesa della prima organizzazione
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per bollette', color: 'FFC000').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per acquisti', color: 'FF99FF').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per pasti fuori', color: 'F4B183').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per cibo', color: '92D050').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese di lavoro', color: 'B4C7E7').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per abbonamenti', color: 'BFBFBF').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per trasporti', color: '7030A0').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per vacanze / gite / svaghi', color: 'A9D18E').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese sanitare', color: '00B0F0').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per bimbe', color: 'FFD966').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per la casa', color: 'C55A11').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese varie', color: 'FFFFFF').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Trasferimenti su altri conti', color: 'FF5E4C').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese amministrative del conto', color: 'FFFF00').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Beneficienza', color: '3F4FFD').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per assicurazioni', color: 'FA01FE').first_or_create!
      ExpenseItem.where(organization_id: first_organization.id, description: 'Spese per regali', color: '00FFEE').first_or_create!


      # Creo i conti corrente della prima organizzazione
      Count.where(
        organization_id: first_organization.id,
        name: 'Conto cointestato BPER per le spese di famiglia',
        description: 'Conto di famiglia per le spese di famiglia',
        count_type: 'bank_account',
        iban: 'IT05B0538712153000003149242',
        monitoring_scope: 'monthly',
        initial_amount: 546.5,
        ordering_number: 1
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Conto cointestato INTESA SAN PAOLO per i risparmi di famiglia',
        description: 'Conto per i risparmi di famiglia',
        count_type: 'savings_account',
        iban: 'IT34A0306912117100000010949',
        monitoring_scope: 'monthly',
        initial_amount: 12478.99,
        ordering_number: 2
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Conto cointestato INTESA SAN PAOLO per i lavori sulla casa',
        description: 'Conto di famiglia per i lavori sulla casa e per le spese grosse a medio termine',
        count_type: 'bank_account',
        iban: 'IT03Q0306912117100000091132',
        monitoring_scope: 'monthly',
        initial_amount: 6.89,
        ordering_number: 3
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Conto personale BANCO POSTE di Michele',
        description: 'Conto personale di Mariana presso Poste Italiane',
        count_type: 'bank_account',
        iban: 'IT11k0760110700001021777204',
        monitoring_scope: 'monthly',
        initial_amount: 4533.18,
        ordering_number: 4
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Conto personale BPER di Mariana',
        description: 'Conto personale di Mariana presso BPER banca',
        count_type: 'bank_account',
        iban: 'IT47M0538712153000003212522',
        monitoring_scope: 'annual',
        initial_amount: 4883.14,
        ordering_number: 5
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: "Piano d'accumulo POSTALE di Michele",
        description: "Piano d'accumulo mensile di Michele presso Poste Italiane",
        count_type: 'accumulation_plan',
        monitoring_scope: 'annual',
        initial_amount: 4200.0,
        ordering_number: 6
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: "Piano d'accumulo BPER di Mariana",
        description: "Piano d'accumulo mensile di Mariana presso BPER banca",
        count_type: 'accumulation_plan',
        monitoring_scope: 'annual',
        initial_amount: 700.36,
        ordering_number: 7
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Libretto BPER di Valentina',
        description: 'Libretto dei risparmi di Valentina presso BPER banca',
        count_type: 'savings_booklet',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 8
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Libretto POSTALE di Valentina',
        description: 'Libretto dei risparmi di Valentina presso Poste Italiane',
        count_type: 'savings_booklet',
        iban: 'IT62E0760103384000053931207',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 9
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Libretto POSTALE di Anastasia',
        description: 'Libretto dei risparmi di Anastasia presso Poste Italiane',
        count_type: 'savings_booklet',
        iban: 'IT93B0760103384000053931597',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 10
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Buoni POSTALI di famiglia',
        description: 'Buoni fruttiferi postali',
        count_type: 'postal_savings_bond',
        monitoring_scope: 'absolute',
        initial_amount: 13000.0,
        ordering_number: 11
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Buoni POSTALI di Valentina',
        description: 'Buoni fruttiferi postali',
        count_type: 'postal_savings_bond',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 12
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Buoni POSTALI di Anastasia',
        description: 'Buoni fruttiferi postali',
        count_type: 'postal_savings_bond',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 13
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Piano di investimento BPER su BTP',
        description: 'Piano di investimento BPER su BTP',
        count_type: 'government_bond_investment_plan',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 14
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Piano di investimento BPER su certificates',
        description: 'Piano di investimento BPER su certificates',
        count_type: 'derivative_investment_plan',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 15
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Piano di investimento BPER su azioni',
        count_type: 'investments_account',
        monitoring_scope: 'annual',
        initial_amount: 0,
        ordering_number: 16
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Fondo ARCA futuro cedola PLUS IV 2031',
        count_type: 'investments_account',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 17
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Libretto POSTALE di famiglia per assicurazioni',
        description: 'Fondo di famiglia per pagamento polizze assicurative',
        count_type: 'bank_account',
        monitoring_scope: 'annual',
        initial_amount: 0,
        ordering_number: 18
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Fondo pensione di Valentina',
        description: 'Fondo pensione di Valentina',
        count_type: 'pension_fund',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 19
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: 'Fondo pensione di Anastasia',
        description: 'Fondo pensione di Anastasia',
        count_type: 'pension_fund',
        monitoring_scope: 'absolute',
        initial_amount: 0,
        ordering_number: 20
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: "Piano d'accumulo di famiglia sull'oro",
        count_type: 'xau_investment_account',
        monitoring_scope: 'annual',
        initial_amount: 0,
        ordering_number: 21
      ).first_or_create!

      Count.where(
        organization_id: first_organization.id,
        name: "Piano d'accumulo di famiglia sull'argento",
        count_type: 'xag_investment_account',
        monitoring_scope: 'annual',
        initial_amount: 0,
        ordering_number: 22
      ).first_or_create!
    else
      puts '****** RAKE ABORTED!!! ******'
    end
  end





  # Importer da file excel dei dati dei movimenti di uno specifico conto corrente
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
    ImportCountMovementsFromXlsxFileCommand.call(Count.find(100), file_paths, expense_items_by_colors)
  end





  # Importer da file excel dello scadenziario
  task import_deadlines_data: :environment do
    organization = Organization.find_by(name: 'Famiglia Battistelli')
    ImportDeadlinesFromXlsxFileCommand.call(organization, ['private/import-xlsx/deadlines/SCADENZIARIO.xlsx'])
  end
end