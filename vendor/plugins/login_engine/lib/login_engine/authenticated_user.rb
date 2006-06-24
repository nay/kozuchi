require 'digest/sha1'

# this model expects a certain database layout and its based on the name/login pattern. 

module LoginEngine
  module AuthenticatedUser

    def self.included(base)
      base.class_eval do

        # use the table name given
        set_table_name LoginEngine.config(:user_table)

        attr_accessor :new_password
      
        validates_presence_of :login
        validates_length_of :login, :within => 3..40
        validates_uniqueness_of :login
        validates_uniqueness_of :email
        validates_format_of :email, :with => /^[^@]+@.+$/

        validates_presence_of :password, :if => :validate_password?
        validates_confirmation_of :password, :if => :validate_password?
        validates_length_of :password, { :minimum => 5, :if => :validate_password? }
        validates_length_of :password, { :maximum => 40, :if => :validate_password? }
  
        protected 
      
        attr_accessor :password, :password_confirmation
      
        after_save :falsify_new_password
        after_validation :crypt_password

      end
      base.extend(ClassMethods)
    end

    module ClassMethods
    
      def authenticate(login, pass)
        u = find(:first, :conditions => ["login = ? AND verified = 1 AND deleted = 0", login])
        return nil if u.nil?
        find(:first, :conditions => ["login = ? AND salted_password = ? AND verified = 1", login, AuthenticatedUser.salted_password(u.salt, AuthenticatedUser.hashed(pass))])
      end

      def authenticate_by_token(id, token)
        # Allow logins for deleted accounts, but only via this method (and
        # not the regular authenticate call)
        u = find(:first, :conditions => ["#{User.primary_key} = ? AND security_token = ?", id, token])
        return nil if u.nil? or u.token_expired?
        return nil if false == u.update_expiry
        u
      end
      
    end
  

    protected
    
      def self.hashed(str)
        # check if a salt has been set...
        if LoginEngine.config(:salt) == nil
          raise "You must define a :salt value in the configuration for the LoginEngine module."
        end
  
        return Digest::SHA1.hexdigest("#{LoginEngine.config(:salt)}--#{str}--}")[0..39]
      end
    
      def self.salted_password(salt, hashed_password)
        hashed(salt + hashed_password)
      end
    
    public
  
    # hmmm, how does this interact with the developer's own User model initialize?
    # We would have to *insist* that the User.initialize method called 'super'
    #
    def initialize(attributes = nil)
      super
      @new_password = false
    end

    def token_expired?
      self.security_token and self.token_expiry and (Time.now > self.token_expiry)
    end

    def update_expiry
      write_attribute('token_expiry', [self.token_expiry, Time.at(Time.now.to_i + 600 * 1000)].min)
      write_attribute('authenticated_by_token', true)
      write_attribute("verified", 1)
      update_without_callbacks
    end

    def generate_security_token(hours = nil)
      if not hours.nil? or self.security_token.nil? or self.token_expiry.nil? or 
          (Time.now.to_i + token_lifetime / 2) >= self.token_expiry.to_i
        return new_security_token(hours)
      else
        return self.security_token
      end
    end

    def set_delete_after
      hours = LoginEngine.config(:delayed_delete_days) * 24
      write_attribute('deleted', 1)
      write_attribute('delete_after', Time.at(Time.now.to_i + hours * 60 * 60))

      # Generate and return a token here, so that it expires at
      # the same time that the account deletion takes effect.
      return generate_security_token(hours)
    end

    def change_password(pass, confirm = nil)
      self.password = pass
      self.password_confirmation = confirm.nil? ? pass : confirm
      @new_password = true
    end
    
    protected

    def validate_password?
      @new_password
    end


    def crypt_password
      if @new_password
        write_attribute("salt", AuthenticatedUser.hashed("salt-#{Time.now}"))
        write_attribute("salted_password", AuthenticatedUser.salted_password(salt, AuthenticatedUser.hashed(@password)))
      end
    end

    def falsify_new_password
      @new_password = false
      true
    end

    def new_security_token(hours = nil)
      write_attribute('security_token', AuthenticatedUser.hashed(self.salted_password + Time.now.to_i.to_s + rand.to_s))
      write_attribute('token_expiry', Time.at(Time.now.to_i + token_lifetime(hours)))
      update_without_callbacks
      return self.security_token
    end

    def token_lifetime(hours = nil)
      if hours.nil?
        LoginEngine.config(:security_token_life_hours) * 60 * 60
      else
        hours * 60 * 60
      end
    end

  end
end
  
