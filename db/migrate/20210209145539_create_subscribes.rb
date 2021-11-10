class CreateSubscribes < ActiveRecord::Migration[6.1]
  def change
    create_table :subscribes do |t|
      t.string :user_id
      t.string :item

      t.timestamps
    end
  end
end
