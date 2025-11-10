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

  # Configure OAuth providers for testing (prevents CI hangs)
  # These are dummy credentials that will be mocked in tests
  config.authentication_providers = {
    google_oauth2: {
      client_id: "test_google_client_id",
      client_secret: "test_google_client_secret"
    },
    github: {
      client_id: "test_github_client_id",
      client_secret: "test_github_client_secret"
    },
    microsoft_graph: {
      client_id: "test_microsoft_client_id",
      client_secret: "test_microsoft_client_secret"
    }
  }

  # Configure admin navigation with nested items (example)
  config.admin_navigation_items = ->(user) {
    [
      {
        label: "Dashboard",
        path: "/admin",
        icon: "fa-solid fa-house"
      },
      {
        label: "Team",
        icon: "fa-solid fa-users",
        children: [
          {label: "Overview", path: "/admin/team/overview"},
          {label: "Members", path: "/admin/team/members"},
          {label: "Calendar", path: "/admin/team/calendar"},
          {label: "Settings", path: "/admin/team/settings"}
        ]
      },
      {
        label: "Projects",
        icon: "fa-solid fa-folder",
        children: [
          {label: "All Projects", path: "/admin/projects"},
          {label: "Active", path: "/admin/projects/active"},
          {label: "Archived", path: "/admin/projects/archived"}
        ]
      },
      {
        label: "Documents",
        icon: "fa-solid fa-file",
        children: [
          {label: "All Documents", path: "/admin/documents"},
          {label: "Drafts", path: "/admin/documents/drafts"},
          {label: "Published", path: "/admin/documents/published"}
        ]
      },
      {
        label: "Tools",
        icon: "fa-solid fa-wrench",
        children: [
          {label: "Import/Export", path: "/admin/tools/import-export"},
          {label: "System Info", path: "/admin/tools/system-info"}
        ]
      },
      {
        label: "Settings",
        path: "/admin/settings",
        icon: "fa-solid fa-gear"
      }
    ]
  }
end
