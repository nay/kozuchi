require File.join(File.dirname(__FILE__), 'spec_helper')

describe 'SubResources' do

  describe "books" do
    before do
      ActionController::Routing.use_controllers! ['books']
      @set = ActionController::Routing::RouteSet.new
      @set.draw do |map|
        map.resources :books, :collection => {:edit_all => :get, :update_all => :put, :destroy_all => :delete}
      end
    end

    it "GET 'books/edit' should be mapped with BooksController#edit_all" do
      url_by_name('edit_books').should ==
        '/books/edit'
      @set.recognize_path("/books/edit", :method => :get).should ==
        {:controller => 'books', :action => 'edit_all'}
    end
    it "PUT 'books' should be mapped with BooksController#update_all" do
      @set.recognize_path("/books", :method => :put).should ==
        {:controller => 'books', :action => 'update_all'}
    end
    it "DELETE 'books' should be mapped with BooksController#destroy_all" do
      @set.recognize_path("/books", :method => :delete).should ==
        {:controller => 'books', :action => 'destroy_all'}
    end
  end

  describe "books - tags using simbol" do
    before do
      ActionController::Routing.use_controllers! ['books', 'tags']
      @set = ActionController::Routing::RouteSet.new
      @set.draw do |map|
        map.resources :books, :sub_resources => :tags
      end
    end
    
    it "GET 'books/3/tags' should be mapped with BooksController#tags" do
      url_by_name('book_tags', :id => 3).should ==
        '/books/3/tags'
      @set.recognize_path("/books/3/tags", :method => :get).should ==
        {:controller => 'books', :action => 'tags', :id => '3'}
    end

    it "POST 'books/3/tags' should be mapped with BookScontroller#create_tag" do
      @set.recognize_path("/books/3/tags", :method => :post).should ==
        {:controller => 'books', :action => 'create_tag', :id => '3'}
    end

    it "GET 'books/3/tag/1' should be mapped with BookScontroller#tag" do
      url_by_name('book_tag', :id => 3, :tag_id => 1).should ==
        '/books/3/tags/1'
      @set.recognize_path("/books/3/tags/1", :method => :get).should ==
        {:controller => 'books', :action => 'tag', :id => '3', :tag_id => '1'}
    end

    it "PUT 'books/3/tag/1' should be mapped with BookScontroller#update_tag" do
      @set.recognize_path("/books/3/tags/1", :method => :put).should ==
        {:controller => 'books', :action => 'update_tag', :id => '3', :tag_id => '1'}
    end

    it "DELETE 'books/3/tag/1' should be mapped with BookScontroller#destroy_tag" do
      @set.recognize_path("/books/3/tags/1", :method => :delete).should ==
        {:controller => 'books', :action => 'destroy_tag', :id => '3', :tag_id => '1'}
    end

    it "GET 'books/3/tags/new' should be mapped with BookScontroller#new_tag" do
      url_by_name('new_book_tag', :id => 3).should ==
        '/books/3/tags/new'
      @set.recognize_path("/books/3/tags/new", :method => :get).should ==
        {:controller => 'books', :action => 'new_tag', :id => '3'}
    end

    it "GET 'books/3/tags/1/edit' should be mapped with BookScontroller#edit_tag" do
      url_by_name('edit_book_tag', :id => 3, :tag_id => 1).should ==
        '/books/3/tags/1/edit'
      @set.recognize_path("/books/3/tags/1/edit", :method => :get).should ==
        {:controller => 'books', :action => 'edit_tag', :id => '3', :tag_id => '1'}
    end
  end
  describe "books - tags using array" do
    before do
      ActionController::Routing.use_controllers! ['books', 'tags']
      @set = ActionController::Routing::RouteSet.new
      @set.draw do |map|
        map.resources :books, :sub_resources => [:tags]
      end
    end
    it "GET 'books/3/tag/1' should be mapped with BookScontroller#tag" do
      url_by_name('book_tag', :id => 3, :tag_id => 1).should ==
        '/books/3/tags/1'
      @set.recognize_path("/books/3/tags/1", :method => :get).should ==
        {:controller => 'books', :action => 'tag', :id => '3', :tag_id => '1'}
    end
  end
  describe "books - tags using hash" do
    before do
      ActionController::Routing.use_controllers! ['books', 'tags']
      @set = ActionController::Routing::RouteSet.new
      @set.draw do |map|
        map.resources :books, :sub_resources => {
          :tags => {
            :only => :show,
            :member => {:vote => :post},
            :collection => {:edit_all => :get, :update_all => :put, :destroy_all => :delete, :copy => :post}
        }}
      end
    end
    it "GET 'books/3/tags/1' should be mapped with BookScontroller#tag" do
      url_by_name('book_tag', :id => 3, :tag_id => 1).should ==
        '/books/3/tags/1'
      @set.recognize_path("/books/3/tags/1", :method => :get).should ==
        {:controller => 'books', :action => 'tag', :id => '3', :tag_id => '1'}
    end
    it "DELETE 'books/3/tag/1' should not be mapped" do
      lambda{@set.recognize_path "/books/3/tags/1", :method => :delete}.should raise_error
    end
    it "POST 'books/3/tags/1/vote should be mapped with BooksController#vote_tag" do
      url_by_name('vote_book_tag', :id => 3, :tag_id => 7).should ==
        '/books/3/tags/7/vote'
      @set.recognize_path("/books/3/tags/1/vote", :method => :post).should ==
        {:controller => 'books', :action => 'vote_tag', :id => '3', :tag_id => '1'}
    end
    it "POST 'books/3/tags/edit should be mapped with BooksConrtoller#edit_tags" do
      url_by_name('edit_book_tags', :id => 3).should ==
        '/books/3/tags/edit'
      @set.recognize_path('/books/3/tags/edit', :method => :get).should ==
        {:controller => 'books', :action => 'edit_tags', :id => '3'}
    end
    it "POST 'books/3/tags should be mapped with BooksController#update_tags" do
      url_by_name('book_tags', :id => 3).should ==
        '/books/3/tags'
      @set.recognize_path('/books/3/tags', :method => :put).should ==
        {:controller => 'books', :action => 'update_tags', :id => '3'}
    end
    it "DELETE 'books/3/tags should be mapped with BooksController#destroy_tag" do
      @set.recognize_path('/books/3/tags', :method => :delete).should ==
        {:controller => 'books', :action => 'destroy_tags', :id => '3'}
    end
    it "POST 'books/3/tags/copy should be mapped with BooksController#copy_tags" do
      @set.recognize_path('/books/3/tags/copy', :method => :post).should ==
        {:controller => 'books', :action => 'copy_tags', :id => '3'}
    end
  end

  describe "books - image using symbol" do
    before do
      ActionController::Routing.use_controllers! ['books', 'image']
      @set = ActionController::Routing::RouteSet.new
      @set.draw do |map|
        map.resources :books, :sub_resource => :image
      end
    end
    it "GET 'books/7/image' should be mapped with BooksController#image" do
      url_by_name('book_image', :id => 7).should ==
        '/books/7/image'
      @set.recognize_path('/books/7/image', :method => :get).should ==
        {:controller => 'books', :action => 'image', :id => '7'}
    end
    it "GET 'books/7/images' should raise error" do
      lambda{url_by_name('book_images', :id => 7)}.should raise_error
      lambda{@set.recognize_path('/books/7/images', :method => :get)}.should raise_error
    end
    it "GET 'books/7/image/edit' should be mapped with BooksController#edit_image" do
      url_by_name('edit_book_image', :id => 7).should ==
        '/books/7/image/edit'
      @set.recognize_path('/books/7/image/edit', :method => :get).should ==
        {:controller => 'books', :action => 'edit_image', :id => '7'}
    end
    it "PUT 'books/7/image' should be mapped with BooksController#update_image" do
      url_by_name('book_image', :id => 7).should ==
        '/books/7/image'
      @set.recognize_path('/books/7/image', :method => :put).should ==
        {:controller => 'books', :action => 'update_image', :id => '7'}
    end
    it "DELETE 'books/7/image' should be mapped with BooksController#destroy_image" do
      @set.recognize_path('/books/7/image', :method => :delete).should ==
        {:controller => 'books', :action => 'destroy_image', :id => '7'}
    end
    it "GET 'books/7/image/new' should be mapped with BooksController#new_image" do
      url_by_name('new_book_image', :id => 7).should ==
        '/books/7/image/new'
      @set.recognize_path('/books/7/image/new', :method => :get).should ==
        {:controller => 'books', :action => 'new_image', :id => '7'}
    end
    it "POST 'books/7/image' should be mapped with BooksController#create_image" do
      @set.recognize_path('/books/7/image', :method => :post).should ==
        {:controller => 'books', :action => 'create_image', :id => '7'}
    end
  end

  describe "books - image using array" do
    before do
      ActionController::Routing.use_controllers! ['books', 'image']
      @set = ActionController::Routing::RouteSet.new
      @set.draw do |map|
        map.resources :books, :sub_resource => [:image]
      end
    end
    it "GET 'books/7/image' should be mapped with BooksController#image" do
      url_by_name('book_image', :id => 7).should ==
        '/books/7/image'
      @set.recognize_path('/books/7/image', :method => :get).should ==
        {:controller => 'books', :action => 'image', :id => '7'}
    end
  end

  describe "books - image using hash" do
    before do
      ActionController::Routing.use_controllers! ['books', 'image']
      @set = ActionController::Routing::RouteSet.new
      @set.draw do |map|
        map.resources :books, :sub_resource => {:image => {
          :only => [:destroy],
          :member => {:rotate => :put}
          }}
      end
    end
    it "DELETE 'books/7/image' should be mapped with BooksController#destroy_image" do
      url_by_name('book_image', :id => 7).should ==
        '/books/7/image'
      @set.recognize_path('/books/7/image', :method => :delete).should ==
        {:controller => 'books', :action => 'destroy_image', :id => '7'}
    end
    it "GET 'books/7/image' should raise error" do
      lambda{@set.recognize_path('/books/7/image', :method => :get)}.should raise_error
    end
    it "PUT 'books/7/image/rotate' should be mapped with BooksController#rotate_image" do
      url_by_name('rotate_book_image', :id => 7).should ==
        '/books/7/image/rotate'
      @set.recognize_path('/books/7/image/rotate', :method => :put).should ==
        {:controller => 'books', :action => 'rotate_image', :id => '7'}
    end
  end


  private
  def url_by_name(name, options = {})
    @set.generate(options.merge(:use_route => name))
  end
end