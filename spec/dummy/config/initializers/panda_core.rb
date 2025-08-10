Panda::Core.configure do |config|
  # Configure the session token cookie name
  config.session_token_cookie = :panda_session

  # Configure the user class for the application
  config.user_class = "Panda::Core::User"

  # Configure the user identity class for the application
  config.user_identity_class = "Panda::Core::UserIdentity"

  # Configure the storage provider (default: :active_storage)
  # config.storage_provider = :active_storage

  # Configure the cache store (default: :memory_store)
  # config.cache_store = :memory_store
end
