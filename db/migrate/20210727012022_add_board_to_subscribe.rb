class AddBoardToSubscribe < ActiveRecord::Migration[6.1]
  def change
    add_column :subscribes, :board, :string
  end
end
