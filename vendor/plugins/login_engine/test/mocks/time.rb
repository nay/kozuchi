require 'time'

Time.class_eval { 
  if !respond_to? :now_old # somehow this is getting defined many times.
    @@advance_by_days = 0
    cattr_accessor :advance_by_days

    class << Time
      alias now_old now
      def now
        if Time.advance_by_days != 0
          return Time.at(now_old.to_i + Time.advance_by_days * 60 * 60 * 24 + 1)
        else
          now_old
        end
      end
    end
  end
}
