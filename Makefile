.PHONY: mysql-up mariadb-up sqlsrv-up php down destroy ps logs exec logs-watch
.PHONY: mysql-init mariadb-init sqlsrv-init exment-ref app-init

# EXMENT_REF: install this branch or tag of Exment (for example 7.2, or 7.2.1) instead of the
# release pinned in exment-boilerplate/composer.lock. It is cloned or checked out in
# exment-boilerplate/exment (exment-admin-core: EXMENT_ADMIN_CORE_REF, default master, in
# exment-boilerplate/exment-admin-core), and composer.dev.json / composer.dev.lock install them
# from those folders. Example: make mysql-init EXMENT_REF=7.2
EXMENT_REF ?=
EXMENT_ADMIN_CORE_REF ?= master
APP_DIR=exment-boilerplate
.PHONY: test-coverage-unit test-coverage-feature test-coverage-merge test-coverage test-browser

mysql-up:
	docker compose -f docker-compose.yml -f docker-compose.mysql.yml up -d
mariadb-up:
	docker compose -f docker-compose.yml -f docker-compose.mariadb.yml up -d
sqlsrv-up:
	docker compose -f docker-compose.yml -f docker-compose.sqlsrv.yml up -d
php:
	docker compose  -f docker-compose.yml exec php bash
down:
	docker compose  -f docker-compose.yml -f docker-compose.mysql.yml -f docker-compose.sqlsrv.yml -f docker-compose.mariadb.yml -f docker-compose.office.yml down
destroy:
	docker compose  -f docker-compose.yml -f docker-compose.mysql.yml -f docker-compose.sqlsrv.yml -f docker-compose.mariadb.yml -f docker-compose.office.yml down --rmi all --volumes --remove-orphans
ps:
	docker compose  -f docker-compose.yml -f docker-compose.mysql.yml -f docker-compose.sqlsrv.yml -f docker-compose.mariadb.yml -f docker-compose.office.yml ps
logs:
	docker compose  -f docker-compose.yml -f docker-compose.mysql.yml -f docker-compose.sqlsrv.yml -f docker-compose.mariadb.yml -f docker-compose.office.yml logs
exec:
	docker compose  -f docker-compose.yml -f docker-compose.mysql.yml -f docker-compose.sqlsrv.yml -f docker-compose.mariadb.yml -f docker-compose.office.yml exec
logs-watch:
	docker compose logs --follow
mysql-init:
	@$(MAKE) exment-ref
	@$(MAKE) down
	@$(MAKE) mysql-up
	@$(MAKE) app-init ENV_FILE=.env.mysql

mariadb-init:
	@$(MAKE) exment-ref
	@$(MAKE) down
	@$(MAKE) mariadb-up
	@$(MAKE) app-init ENV_FILE=.env.mariadb

sqlsrv-init:
	@$(MAKE) exment-ref
	@$(MAKE) down
	@$(MAKE) sqlsrv-up
	@$(MAKE) ps
	@$(MAKE) logs
	# (sqlsrv-create-db waits until the server answers)
	docker compose -f docker-compose.yml -f docker-compose.sqlsrv.yml run --rm -T sqlsrv-create-db
	@$(MAKE) ps
	@$(MAKE) logs
	@$(MAKE) app-init ENV_FILE=.env.sqlsrv

# Check out EXMENT_REF (on the host, with git). Nothing when EXMENT_REF is empty.
exment-ref:
ifneq ($(EXMENT_REF),)
	@test -d $(APP_DIR)/exment || git clone -q https://github.com/exceedone/exment.git $(APP_DIR)/exment
	git -C $(APP_DIR)/exment fetch -q origin $(EXMENT_REF)
	git -C $(APP_DIR)/exment checkout -q --detach FETCH_HEAD
	@test -d $(APP_DIR)/exment-admin-core || git clone -q https://github.com/exceedone/exment-admin-core.git $(APP_DIR)/exment-admin-core
	git -C $(APP_DIR)/exment-admin-core fetch -q origin $(EXMENT_ADMIN_CORE_REF)
	git -C $(APP_DIR)/exment-admin-core checkout -q --detach FETCH_HEAD
	@echo "exment: $$(git -C $(APP_DIR)/exment log -1 --oneline)"
	@echo "exment-admin-core: $$(git -C $(APP_DIR)/exment-admin-core log -1 --oneline)"
endif

# The steps after the containers are up (ENV_FILE: .env.mysql, .env.mariadb or .env.sqlsrv).
# artisan runs as root, so .env, storage and bootstrap/cache are given back to www-data at the end:
# otherwise the web installer stops on "write permission" of .env and the template list fails (500).
app-init:
ifneq ($(EXMENT_REF),)
	docker compose -f docker-compose.yml exec -T php cp composer.dev.json composer.json
	docker compose -f docker-compose.yml exec -T php cp composer.dev.lock composer.lock
endif
	docker compose -f docker-compose.yml exec -T php bash -c "find . -path '*/.git' -prune -o -print0 | xargs -0 chown www-data:www-data"
	docker compose -f docker-compose.yml exec -T -e COMPOSER_PROCESS_TIMEOUT=600 php composer install
	docker compose -f docker-compose.yml exec -T php cp $(ENV_FILE) .env
	docker compose -f docker-compose.yml exec -T php php artisan key:generate
	docker compose -f docker-compose.yml exec -T php php artisan passport:key --force
	docker compose -f docker-compose.yml exec -T php chown -R www-data:www-data .env storage bootstrap/cache
ifneq ($(EXMENT_REF),)
	@docker compose -f docker-compose.yml exec -T php test -L vendor/exceedone/exment || { echo "vendor/exceedone/exment is not the folder exment: check composer.dev.json"; exit 1; }
endif

# --- Coverage targets -------------------------------------------------------
# COV_DIR: where per-suite *.cov dumps land (inside the container path).
COV_DIR=storage/logs/coverage
EXMENT_TESTS=./vendor/exceedone/exment/tests

# Run unit tests with --coverage-php so the merge step can pick them up.
test-coverage-unit:
	docker compose -f docker-compose.yml exec -T -e COMPOSER_PROCESS_TIMEOUT=0 php \
	  bash -c "mkdir -p $(COV_DIR) && php artisan exment:inittest --yes && php -d pcov.enabled=1 -d memory_limit=1024M vendor/bin/phpunit $(EXMENT_TESTS)/Unit --coverage-php $(COV_DIR)/unit.cov"

# Run feature tests with --coverage-php.
test-coverage-feature:
	docker compose -f docker-compose.yml exec -T -e COMPOSER_PROCESS_TIMEOUT=0 php \
	  bash -c "mkdir -p $(COV_DIR) && php artisan exment:inittest --yes && php -d pcov.enabled=1 -d memory_limit=1024M vendor/bin/phpunit $(EXMENT_TESTS)/Feature --coverage-php $(COV_DIR)/feature.cov"

# Merge .cov files and emit clover/html/text reports under $(COV_DIR)/merged/.
test-coverage-merge:
	docker compose -f docker-compose.yml exec -T php php -d memory_limit=2048M /usr/local/bin/merge-coverage.php

# One-shot: unit + feature + merge.
test-coverage:
	@$(MAKE) test-coverage-unit
	@$(MAKE) test-coverage-feature
	@$(MAKE) test-coverage-merge

# Browser tests segfault under PCOV; run them with pcov.enabled=0 and no coverage.
test-browser:
	docker compose -f docker-compose.yml exec -T -e COMPOSER_PROCESS_TIMEOUT=0 php \
	  bash -c "php artisan exment:inittest --yes && php -d pcov.enabled=0 vendor/bin/phpunit $(EXMENT_TESTS)/Browser --no-coverage"
