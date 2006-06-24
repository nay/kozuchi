require File.dirname(__FILE__) + '/../test_helper'
class UserTest < Test::Unit::TestCase

  # load the fixture into the developer-specified table using the custom
  # 'fixture' method.
  fixture :users, :table_name => LoginEngine.config(:user_table), :class_name => "User"
 
  def setup
    LoginEngine::CONFIG[:salt] = "test-salt"
  end 
    
  def test_auth   
    assert_equal users(:bob), User.authenticate("bob", "atest")    
    assert_nil User.authenticate("nonbob", "atest")
  end


  def test_passwordchange
        
    users(:longbob).change_password("nonbobpasswd")
    users(:longbob).save
    assert_equal users(:longbob), User.authenticate("longbob", "nonbobpasswd")
    assert_nil User.authenticate("longbob", "alongtest")
    users(:longbob).change_password("alongtest")
    users(:longbob).save
    assert_equal users(:longbob), User.authenticate("longbob", "alongtest")
    assert_nil User.authenticate("longbob", "nonbobpasswd")
        
  end
  
  def test_disallowed_passwords
    
    u = User.new    
    u.login = "nonbob"
    u.email = "bobs@email.com"

    u.change_password("tiny")
    assert !u.save     
    assert u.errors.invalid?('password')

    u.change_password("hugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehugehuge")
    assert !u.save     
    assert u.errors.invalid?('password')
        
    u.change_password("")
    assert !u.save    
    assert u.errors.invalid?('password')
        
    u.change_password("bobs_secure_password")
    assert u.save     
    assert u.errors.empty?
        
  end
  
  def test_bad_logins

    u = User.new  
    u.change_password("bobs_secure_password")
    u.email = "bobs@email.com"

    u.login = "x"
    assert !u.save     
    assert u.errors.invalid?('login')
    
    u.login = "hugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhugebobhug"
    assert !u.save     
    assert u.errors.invalid?('login')

    u.login = ""
    assert !u.save
    assert u.errors.invalid?('login')

    u.login = "okbob"
    assert u.save  
    assert u.errors.empty?
      
  end


  def test_collision
    u = User.new
    u.login = "existingbob"
    u.change_password("bobs_secure_password")
    assert !u.save
  end


  def test_create
    u = User.new
    u.login = "nonexistingbob"
    u.change_password("bobs_secure_password")
    u.email = "bobs@email.com"
      
    assert u.save  
    
  end

  def test_email_should_be_nominally_valid
    u = User.new
    u.login = "email_test"
    u.change_password("email_test_password")

    assert !u.save
    assert u.errors.invalid?('email')

    u.email = "invalid_email"
    assert !u.save
    assert u.errors.invalid?('email')

    u.email = "valid@email.com"
    assert u.save
  end

end
