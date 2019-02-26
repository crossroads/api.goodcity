class CreateProcessChecklist < ActiveRecord::Migration
  def change
    create_table :process_checklists do |t|
      t.string :text_en
      t.string :text_zh_tw
      t.references :booking_type, index: true, foreign_key: true
    end

    create_table :orders_process_checklists do |t|
      t.references :order, index: true, foreign_key: true
      t.references :process_checklist, index: true, foreign_key: true
    end
  end
end
