# Be sure to restart your server when you modify this file.

# Your secret key is used for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!

# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
# You can use `rake secret` to generate a secure secret key.

# Make sure your secret_key_base is kept private
# if you're sharing your code publicly.
Kozuchi::Application.config.secret_key_base = defined?(KOZUCHI_SECRET_KEY_BASE) ? KOZUCHI_SECRET_KEY_BASE : 'dcbe6f1a5ce2be8a9bc6b3a5b254c238de397e7b3fd46905e2918d76293aa357b41727af05353f3f408db808134c37d8022f47a4c09d78468fbeace68993bc9d'
puts "Please set KOZUCHI_SECRET_KEY_BASE in your hosting.rb for security!\n\n" unless defined?(KOZUCHI_SECRET_KEY_BASE)
