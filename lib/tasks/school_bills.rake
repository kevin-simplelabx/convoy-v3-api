namespace :school_bills do
  desc "Give first invoices issued before the details fix their line, family and bill-to code. DRY_RUN=1 counts only; safe to run twice"
  task backfill_first_details: :environment do
    dry = ENV["DRY_RUN"].present?
    SchoolBills::BackfillFirstDetails.call(dry_run: dry).each do |code, r|
      puts "#{code}: checked #{r.checked}, #{dry ? 'would update' : 'updated'} #{r.updated}, left as is #{r.skipped}"
    end
    puts "Dry run, nothing written" if dry
  end
end
