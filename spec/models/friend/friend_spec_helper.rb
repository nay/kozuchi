def new_rejection(user_id, target_id)
  r = Friend::Rejection.new(:target_id => target_id)
  r.user_id = user_id
  r
end

def new_acceptance(user_id, target_id)
  a = Friend::Acceptance.new(:target_id => target_id)
  a.user_id = user_id
  a
end

def new_request(user_id, sender_id)
  Friend::Request.new(:user_id => user_id, :sender_id => sender_id)
end

def find_request(user_id, sender_id)
  Friend::Request.find_by(user_id: user_id, sender_id: sender_id)
end

def find_acceptance(user_id, target_id)
  Friend::Acceptance.find_by(user_id: user_id, target_id: target_id)
end