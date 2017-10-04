ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  map.new_voucher_menu  '/new_voucher_menu',  :controller => 'pages', :action => 'new_voucher_menu'
  map.edit_voucher_menu  '/edit_voucher_menu',  :controller => 'pages', :action => 'edit_voucher_menu'
  map.view_voucher_menu  '/view_voucher_menu',  :controller => 'pages', :action => 'view_voucher_menu'
  map.void_voucher_menu  '/void_voucher_menu',  :controller => 'pages', :action => 'void_voucher_menu'
  map.edit_this_voucher  '/edit_this_voucher',  :controller => 'pages', :action => 'edit_this_voucher'
  map.view_this_voucher  '/view_this_voucher',  :controller => 'pages', :action => 'view_this_voucher'
  map.my_vouchers  '/my_vouchers',  :controller => 'pages', :action => 'my_vouchers'
  map.search_vouchers_menu  '/search_vouchers_menu',  :controller => 'pages', :action => 'search_vouchers_menu'
  map.update_cheque_number  '/update_cheque_number',  :controller => 'pages', :action => 'update_cheque_number'
  map.update_cash_book_menu  '/update_cash_book_menu',  :controller => 'pages', :action => 'update_cash_book_menu'
  map.download_cash_book  '/download_cash_book',  :controller => 'pages', :action => 'download_cash_book'
  map.upload_cash_book  '/upload_cash_book',  :controller => 'pages', :action => 'upload_cash_book'
  map.insufficient_balance  '/insufficient_balance',  :controller => 'pages', :action => 'insufficient_balance'
  map.personal_details  '/personal_details',  :controller => 'pages', :action => 'personal_details'
  map.voucher_downloadable  '/voucher_downloadable',  :controller => 'pages', :action => 'voucher_downloadable'
  map.print_voucher  '/print_voucher',  :controller => 'pages', :action => 'print_voucher'
  map.new_user  '/new_user',  :controller => 'pages', :action => 'new_user'
  map.update_user_profile  '/update_user_profile',  :controller => 'pages', :action => 'update_user_profile'
  map.view_users  '/view_users',  :controller => 'pages', :action => 'view_users'
  map.remove_user  '/remove_user',  :controller => 'pages', :action => 'remove_user'
  map.new_workings  '/new_workings',  :controller => 'pages', :action => 'new_workings'
  map.edit_workings  '/edit_workings',  :controller => 'pages', :action => 'edit_workings'
  map.edit_this_workings  '/edit_this_workings',  :controller => 'pages', :action => 'edit_this_workings'
  map.view_workings  '/view_workings',  :controller => 'pages', :action => 'view_workings'
  map.void_workings  '/void_workings',  :controller => 'pages', :action => 'void_workings'
  map.login  '/login',  :controller => 'pages', :action => 'login'
  map.lock_screen  '/lock_screen',  :controller => 'pages', :action => 'lock_screen'
  map.unlock_screen  '/unlock_screen',  :controller => 'pages', :action => 'unlock_screen'
  map.logout  '/logout',  :controller => 'pages', :action => 'logout'
  map.change_password  '/change_password',  :controller => 'pages', :action => 'change_password'
  map.reset_password  '/reset_password',  :controller => 'pages', :action => 'reset_password'
  map.todays_vouchers  '/todays_vouchers',  :controller => 'pages', :action => 'todays_vouchers'
  map.this_weeks_vouchers  '/this_weeks_vouchers',  :controller => 'pages', :action => 'this_weeks_vouchers'
  map.this_months_vouchers  '/this_months_vouchers',  :controller => 'pages', :action => 'this_months_vouchers'
  map.this_years_vouchers  '/this_years_vouchers',  :controller => 'pages', :action => 'this_years_vouchers'

  map.new_account_details  '/new_account_details',  :controller => 'pages', :action => 'new_account_details'
  map.edit_account_details  '/edit_account_details',  :controller => 'pages', :action => 'edit_account_details'
  map.view_account_details  '/view_account_details',  :controller => 'pages', :action => 'view_account_details'
  map.void_account_details  '/void_account_details',  :controller => 'pages', :action => 'void_account_details'
  map.edit_this_account  '/edit_this_account',  :controller => 'pages', :action => 'edit_this_account'

  map.new_income  '/new_income',  :controller => 'pages', :action => 'new_income'
  map.edit_income  '/edit_income',  :controller => 'pages', :action => 'edit_income'
  map.view_income  '/view_income',  :controller => 'pages', :action => 'view_income'
  map.void_income  '/void_income',  :controller => 'pages', :action => 'void_income'
  map.edit_this_income  '/edit_this_income',  :controller => 'pages', :action => 'edit_this_income'

  #map.new_voucher_menu  '/new_voucher_menu',  :controller => 'pages', :action => 'new_voucher_menu'
  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
   map.root :controller => "pages", :action => "home"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing or commenting them out if you're using named routes and resources.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
