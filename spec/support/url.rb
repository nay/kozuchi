def current_hash
  current_url =~ (/^.*#(.*)$/)
  $1
end
