# Based on https://gist.github.com/gambala/4874e2b41a52ac043a274a61f5d7726b
#
# There's nothing here you can't do the long way. This is just a collection of (hopefully intuitive) shortcuts
# to ease common development tasks and serve as a reference.
#
# To use this file:
#
#   $ make <target command> <any arguments>
#
#
#
# RUN_ARGS
#
# RUN_ARGS allows you to run make commands with any set of arguments.
#
# For example, these lines are the same:
#   > make g devise:install
#   > bundle exec rails generate devise:install
# And these:
#   > make add-migration add_deleted_at_to_users deleted_at:datetime
#   > bundle exec rails g migration add_deleted_at_to_users deleted_at:datetime
# And these:
#   > make add-model Order user:references record:references{polymorphic}
#   > bundle exec rails g model Order user:references record:references{polymorphic}
RUN_ARGS := $(wordlist 2, $(words $(MAKECMDGOALS)), $(MAKECMDGOALS))

# If nothing is passed, show the help
.DEFAULT_GOAL := help

###Rails-Commands: ## .
run-console:
	bundle exec rails console
c: run-console ## Starts a rails console

run-generate:
	bundle exec rails generate $(RUN_ARGS)
g: run-generate ## Runs the rails generator

run-rails:
	bundle exec bin/dev
s: run-rails ## Starts the rails server

run-tests:
	rails test $(RUN_ARGS)
t: run-tests ## Runs the provided test(s)

docker-run:
	docker compose up

ds: docker-run ## Run the docker server

docker-restart: ## stop and start the docker server
	docker compose down
	docker compose up

###: ## .
###Database-Commands: ## .
db: ## Connect to the rails postgres db
	rails db

migrate: ## Run any outstanding rails migrations
	bundle exec rails db:migrate

rollback: ## Rollback the most recent rails migration
	bundle exec rails db:rollback

seed: ## Populate the dev database with fresh data
	bundle exec rails db:seed

docker-seed: ## Seed or reseed your docker instance
	docker compose run --rm web rails db:create db:migrate db:seed

add-migration: ## Generate a rails migration
	bundle exec rails g migration $(RUN_ARGS)

###: ## .
###Linting-Commands: ## .
lint-ruby: ## Run ruby syntax clean up
	bundle exec rubocop -a

lint-audit: ## Run ruby security checks
	brakeman
	bundle exec ruby-audit check
	bundle-audit update; bundle-audit check

###: ## .
###Dependency-Commands: ## .
ruby-install: ## Gets ruby dependencies up to date
	bundle check || bundle install

yarn-install: ## Gets js dependencies up to date
	yarn install

yarn-install-hard: ## Remove existing node_modules and install js dependencies anew
	rm -rf node_modules
	yarn install

install: ruby-install yarn-install ## Updates all our dependencies

###: ## .
###Git-Commands: ## .
match-main: ## Update our branch with changes in main
	git stash save -u
	git checkout main
	git pull
	git checkout -
	git merge --no-edit -
	git stash pop

###: ## .
###Combo-Commands: ## .
update: install migrate ## Update dependencies and run migrations

update-with-main: match-main install migrate ## Merge main, update dependencies and run migrations

###: ## .
###Dev-Env-Setup-Commands: ## .
lint-ruby-setup: ## Setup ruby linting
	bundle exec rubocop --auto-gen-config

lint-setup-audits: ## Setup ruby auditors
	gem install brakeman ruby_audit bundler-audit

docker-build:
	docker compose build

docker-install: docker-build docker-seed ## Setup the docker instance from scratch

###: ## .
# Self-documented makefile from https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help:  ## Shows help
	@grep -E '^[#\ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; { split($$1, C, " "); printf "\033[36m%-30s\033[0m %s\n", C[1], $$2}'
