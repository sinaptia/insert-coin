# insert-coin

This is a [Ruby on Rails](https://rubyonrails.org) [application template](https://guides.rubyonrails.org/rails_application_templates.html).

![Insert Coin](/insert-coin.jpg)

## Usage

Simple. Create a new app by running:

```sh
rails new -m https://raw.githubusercontent.com/sinaptia/insert-coin/main/template.rb -d postgresql -a propshaft --skip-hotwire --skip-jbuilder -T -j esbuild -c tailwind APP_NAME
```

You can also clone this repository and run locally. Useful if you're experimenting or want so change something.

### If you're running docker

If you don't have ruby installed natively and rely only in docker for local development, you can also run use this template. There are a few more steps, though:

```sh
docker run -it -v $PWD:/app -w /app --rm ruby:3.2-alpine sh -c 'apk add --no-cache --update build-base git imagemagick linux-headers nodejs npm postgresql-dev tzdata yarn && gem install rails && rails new -m https://raw.githubusercontent.com/sinaptia/insert-coin/main/template.rb -d postgresql -a propshaft --skip-hotwire --skip-jbuilder -T -j esbuild -c tailwind APP_NAME'
```

## What does it do?

It creates a new rails 7 app with these features:

* docker for local development
* postgresql db
* propshaft (new asset pipeline)
* jsbundling-rails (esbuild)
* cssbundling-rails
* tailwind
* no hotwire
* no jbuilder
* [rspec-rails](https://github.com/rspec/rspec-rails)
* [shoulda-matchers](https://github.com/thoughtbot/shoulda-matchers)
* [factory_bot_rails](https://github.com/thoughtbot/factory_bot_rails)
* [faker](https://github.com/faker-ruby/faker)
* [dotenv-rails](https://github.com/bkeepers/dotenv)
* [devise](https://github.com/heartcombo/devise)
* [devise-i18n](https://github.com/tigrish/devise-i18n)
* [omniauth-facebook](https://github.com/simi/omniauth-facebook) (optional)
* [omniauth-google-oauth2](https://github.com/zquestz/omniauth-google-oauth2) (optional)
* [pundit](https://github.com/varvet/pundit) (optional)
* [good_job](https://github.com/bensheldon/good_job) (background jobs, optional)
* [rails-i18n](https://github.com/svenfuchs/rails-i18n)
* **[standard ruby](https://github.com/testdouble/standard)**
* **[standard js](https://github.com/standard/standard)**
* [react](https://react.dev/)
* [mount-react-components](https://github.com/sinaptia/mount-react-components)

After running the `rails new` command you should have a rails 7 app with all of the above already set up. You only need to run:

```sh
bundle exec rails db:create db:migrate
```

and you can start working on your brand new app!

### If you're running docker

You need to run:

```sh
docker-compose build web
docker-compose run web bundle
docker-compose run web yarn install
docker-compose run web rails db:create db:migrate
docker-compose up
```
