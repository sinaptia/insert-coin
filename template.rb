require "net/http"

def get_file_content(filename)
  if File.exist? "#{File.dirname(__FILE__)}/templates/#{filename}"
    IO.read "#{File.dirname(__FILE__)}/templates/#{filename}"
  else
    uri = "https://raw.githubusercontent.com/sinaptia/insert-coin/main/templates/#{filename}"
    Net::HTTP.get URI(uri)
  end
end

def add_gem(name)
  gem name unless IO.read("Gemfile") =~ /^\s*gem ['"]#{name}['"]/
end

def check_options!
  valid_options = {
    database: "postgresql",
    asset_pipeline: "propshaft",
    skip_hotwire: true,
    skip_jbuilder: true,
    skip_test: true,
    javascript: "esbuild",
    css: "tailwind"
  }

  valid_options.each do |k, v|
    if options[k] != v
      abort "#{k} should be #{v}, but it's #{options[k]}"
    end
  end
end

def setup_devise
  generate "devise:install"
  environment "config.action_mailer.default_url_options = {host: \"localhost\", port: 3000}", env: :development
  generate "devise", "User"
  inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  before_action :authenticate_user!\n"
end

def setup_docker
  add_file "Dockerfile", get_file_content("Dockerfile")
  add_file "docker-compose.yml", get_file_content("docker-compose.yml")
  gsub_file "docker-compose.yml", "APP_NAME", app_name
  add_file "bin/entrypoint.sh", get_file_content("entrypoint.sh")
end

def setup_dotenv
  add_file ".env", "DATABASE_URL=postgresql://postgres:password@db/#{app_name}_development\n"
  add_file ".env.sample", "DATABASE_URL=DATABASE_URL\n"
end

def setup_good_job
  generate "good_job:install"
  application "config.active_job.queue_adapter = :good_job"
  route "mount GoodJob::Engine => \"jobs\""
end

def setup_js
  run "yarn add react react-dom mount-react-components"
  run "yarn add standard --dev"

  append_to_file "app/javascript/application.js", <<~STR

    import { mountComponents } from 'mount-react-components'

    const components = {}

    mountComponents(components)
  STR

  insert_into_file "package.json", " --loader:.js=jsx", after: "--public-path=assets"
end

def setup_omniauth(omniauth_providers)
  return if omniauth_providers.none?

  gsub_file "app/models/user.rb", ":trackable and :omniauthable", "and :trackable"
  gsub_file "app/models/user.rb", "devise :database_authenticatable, :registerable,", "devise :database_authenticatable, :omniauthable, :registerable,"

  omniauth_providers.each do |omniauth_provider|
    append_to_file ".env.sample", <<~STR
      #{omniauth_provider[:app_id]}=#{omniauth_provider[:app_id]}
      #{omniauth_provider[:secret]}=#{omniauth_provider[:secret]}
    STR

    append_to_file ".env", <<~STR
    #{omniauth_provider[:app_id]}=
    #{omniauth_provider[:secret]}=
    STR

    insert_into_file "config/initializers/devise.rb", after: "# config.omniauth :github, 'APP_ID', 'APP_SECRET', scope: 'user,public_repo'\n" do
      "  config.omniauth :#{omniauth_provider[:provider]}, ENV[\"#{omniauth_provider[:app_id]}\"], ENV[\"#{omniauth_provider[:secret]}\"], scope: \"#{omniauth_provider[:scope]}\"\n"
    end
  end

  provider_names = omniauth_providers.map { |op| ":#{op[:provider]}" }

  insert_into_file "app/models/user.rb", "\n  devise omniauth_providers: [#{provider_names.join(", ")}]\n", after: ":validatable\n"

  generate "model", "Identity", "uid:string", "provider:string", "user:belongs_to"
  # We need this because it would fail if we add this field in the generator above.
  # For some reason it needs to connect to the db...
  insert_into_file Dir["**/*create_identities*"].first, "    t.json :auth_data\n", after: "t.belongs_to :user, null: false, foreign_key: true\n"

  insert_into_file "app/models/user.rb", "\n  has_many :identities\n", after: "devise omniauth_providers: [#{provider_names.join(", ")}]\n"

  add_file "app/controllers/users/omniauth_callbacks_controller.rb", get_file_content("omniauth_callbacks_controller.rb")

  omniauth_providers.each do |omniauth_provider|
    insert_into_file "app/controllers/users/omniauth_callbacks_controller.rb", before: "private" do
      <<~STR
        def #{omniauth_provider[:provider]}
          omniauth_authentication
        end
      STR
    end
  end

  insert_into_file "config/routes.rb", ", controllers: {omniauth_callbacks: \"users/omniauth_callbacks\"}", after: "devise_for :users"
end

def setup_pundit
  generate "pundit:install"

  inject_into_class "app/controllers/application_controller.rb", "ApplicationController", "  include Pundit::Authorization\n\n"
end

def setup_rspec
  generate "rspec:install"
end

def setup_shoulda_matchers
  insert_into_file "spec/rails_helper.rb" do
    <<~STR

    Shoulda::Matchers.configure do |config|
      config.integrate do |with|
        with.test_framework :rspec
        with.library :rails
      end
    end
    STR
  end
end

check_options!

add_good_job = yes? "Do you want to add good_job (background jobs)?"
add_omniauth_facebook = yes? "Do you want to add omniauth-facebook?"
add_omniauth_google_oauth2 = yes? "Do you want to add omniauth-google-oauth2?"
add_pundit = yes? "Do you want to add pundit (authorization)?"

gem_group :development, :test do
  add_gem "dotenv-rails"
  add_gem "standard"
end

gem_group :test do
  add_gem "factory_bot_rails"
  add_gem "faker"
  add_gem "rspec-rails"
  add_gem "shoulda-matchers"
end

add_gem "devise"
add_gem "devise-i18n"
add_gem "good_job" if add_good_job
add_gem "omniauth-facebook" if add_omniauth_facebook
add_gem "omniauth-google-oauth2" if add_omniauth_google_oauth2
add_gem "omniauth-rails_csrf_protection" if add_omniauth_facebook || add_omniauth_google_oauth2
add_gem "pundit" if add_pundit
add_gem "rails-i18n"

after_bundle do
  setup_docker

  setup_rspec
  setup_shoulda_matchers
  setup_dotenv
  setup_devise
  setup_good_job if add_good_job

  omniauth_providers = []
  if add_omniauth_facebook
    omniauth_providers << {
      provider: "facebook",
      app_id: "FACEBOOK_APP_ID",
      secret: "FACEBOOK_SECRET",
      scope: "email,public_profile"
    }
  end
  if add_omniauth_google_oauth2
    omniauth_providers << {
      provider: "google_oauth2",
      app_id: "GOOGLE_CLIENT_ID",
      secret: "GOOGLE_CLIENT_SECRET",
      scope: "email profile openid"
    }
  end

  setup_omniauth omniauth_providers
  setup_pundit if add_pundit
  setup_js

  run "bundle exec standardrb --fix"
  run "yarn standard --fix"
end
