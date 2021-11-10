Rails.application.routes.draw do
  devise_for :users
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  get '/ptt/eat' , to: 'ptt#eat'
  get '/ptt/request_headers' , to: 'ptt#request_headers'
  get '/ptt/response_headers' , to: 'ptt#response_headers'
  get '/ptt/request_body' , to: 'ptt#request_body'
  get '/ptt/response_body' ,to: 'ptt#show_response_body'
  get '/ptt/sent_request' ,to: 'ptt#sent_request'
  post '/ptt/webhook' ,to: 'ptt#webhook'
end
