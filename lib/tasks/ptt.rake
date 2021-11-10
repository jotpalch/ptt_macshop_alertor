namespace :ptt do
  desc "TODO"
  task subscribe: :environment do
    PushSubscribe.new.push
  end

end
