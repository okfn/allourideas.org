ActionController::Routing::Routes.draw do |map|
  map.resource :session, :controller => "clearance/sessions", :only => [:new, :create, :destroy]
  map.signin '/sign_in', :controller => "clearance/sessions", :action => :new
  map.signout '/sign_out', :controller => "clearance/sessions", :action => :destroy
  map.resource :passwords, :controller => "clearance/passwords"

  map.resources :questions,
    :collection => {
    },
    :member => {
      :admin => :get,
      :update_name => :put,
      :add_idea => :post,
      :toggle => :post,
      :toggle_autoactivate => :post,
      :delete_logo => :delete,
      :addphotos => :get,
      :upload_photos => :post,
      :visitor_voting_history => :get,
      :about => :get,
      :results => :get,
      :export => :get,
      :intro => :get,
      :scatter_plot_user_vs_seed_ideas => :get,
      :word_cloud => :get,
      :voter_map => :get,
      :timeline_graph => :get,
      :density_graph => :get,
      :choices_by_creation_date => :get,
      :scatter_votes_by_session => :get,
      :scatter_votes_vs_skips => :get,
      :scatter_score_vs_votes => :get
    } do |question|
	  question.resources :prompts, 
		  :only => [:vote, :skip, :flag],
		  :member => {
		  	:vote => :post,
			:skip => :post,
                        :flag => :post,
                  }
	  question.resources :choices, 
		  :only => [:show, :votes, :update],
		  :member => {
		  	:activate => :get, # these shouldn't be get requests, but they need to work in email
        :deactivate => :get,
        :rotate => :post,
        :votes => :get,
        :toggle => :post
		  }
	  end

  map.resources :consultations, :member => { :create_earl => :post, :admin => :get } do |consultation|
    consultation.resources :earls, :only => [:show, :export_list], :collection => {:export_list=> :get}, :as => 'category'
  end
  map.resources :clicks, :collection => {:export=> :get}
  #map.connect '/questions/:question_id/choices/:id', :controller => 'choices', :action => 'show'
  map.toggle_choice_status '/questions/:earl_id/choices/:id/toggle.:format', :controller => 'choices', :action => 'toggle', :conditions => { :method => :post }
  
  map.about '/about', :controller => 'home', :action => 'about'
  map.admin '/admin', :controller => 'home', :action => 'admin'
  map.privacy '/privacy', :controller => 'home', :action => 'privacy'
  map.privacy_2009_07_06 '/privacy-2009-07-06', :controller => 'home', :action => 'privacy-2009-07-06'
  map.tour '/tour', :controller => 'home', :action => 'tour'
  map.example '/example', :controller => 'home', :action => 'example'
  map.connect '/signup', :controller => 'users', :action => 'new'
  map.root :controller => 'home', :action => 'index'
  #map.toggle_question '/questions/:id/toggle', :controller => 'questions'
  map.abingoTest "/abingo/:action/:id", :controller=> :abingo_dashboard
  map.googletracking "/no_google_tracking", :controller=> :home, :action => :no_google_tracking
   
  
  map.connect '/export/:name', :controller => 'exports', :action => 'download'

  map.connect '/prompts/load_wikipedia_marketplace', :controller => 'prompts', :action => 'load_wikipedia_marketplace'
  map.connect '/wikipedia-banner-challenge/gallery', :controller => 'home', :action => 'wikipedia_banner_challenge_gallery'

  map.add_photos '/:id/addphotos', :controller => 'questions', :action => 'add_photos'
  map.connect '/:id/:action', :controller => 'questions'
  # rake routes
  # http://guides.rubyonrails.org/routing.html
end
