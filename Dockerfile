FROM unblibraries/drupal:alpine-nginx-php7-8.x-composer
MAINTAINER UNB Libraries <libsupport@unb.ca>

LABEL name="loyalistresearchnet.org"
LABEL vcs-ref=""
LABEL vcs-url="https://github.com/unb-libraries/loyalistresearchnet.org"

ARG COMPOSER_DEPLOY_DEV=no-dev

# Universal environment variables.
ENV DEPLOY_ENV prod
ENV DRUPAL_DEPLOY_CONFIGURATION TRUE
ENV DRUPAL_SITE_ID loyaltres
ENV DRUPAL_SITE_URI loyalistresearchnet.org
ENV DRUPAL_SITE_UUID 4f7e5705-9fb7-4e1b-a2fe-032e04e64e9a
ENV DRUPAL_CONFIGURATION_EXPORT_SKIP devel

# Newrelic.
ENV NEWRELIC_PHP_VERSION 7.2.0.191
ENV NEWRELIC_PHP_ARCH musl

# Add Mail Sending, Rsyslog
RUN apk --update add postfix rsyslog  && \
  rm -f /var/cache/apk/* && \
  touch /var/log/nginx/access.log && touch /var/log/nginx/error.log
COPY package-conf/postfix/main.cf /etc/postfix/main.cf

# Add package conf.
COPY ./package-conf /package-conf
RUN mv /package-conf/postfix/main.cf /etc/postfix/main.cf && \
  mkdir -p /etc/rsyslog.d && \
  mv /package-conf/rsyslog/21-logzio-nginx.conf /etc/rsyslog.d/21-logzio-nginx.conf && \
  mv /package-conf/nginx/app.conf /etc/nginx/conf.d/app.conf && \
  mv /package-conf/php/app-php.ini /etc/php7/conf.d/zz_app.ini && \
  mv /package-conf/php/app-php-fpm.conf /etc/php7/php-fpm.d/zz_app.conf && \
  rm -rf /package-conf

# Scripts.
COPY ./scripts/container /scripts
RUN /scripts/DeployUpstreamContainerScripts.sh

# Remove upstream build and replace it with ours.
RUN /scripts/deleteUpstreamTree.sh
COPY build/ ${TMP_DRUPAL_BUILD_DIR}
ENV DRUPAL_BUILD_TMPROOT ${TMP_DRUPAL_BUILD_DIR}/webroot

# Deploy the generalized profile and makefile into our specific one.
RUN /scripts/deployGeneralizedProfile.sh && \
  # Build Drupal tree.
  /scripts/buildDrupalTree.sh ${COMPOSER_DEPLOY_DEV} && \
  # Install NewRelic.
  /scripts/installNewRelic.sh

# Copy configuration.
COPY ./config-yml ${TMP_DRUPAL_BUILD_DIR}/config-yml

# Custom modules not tracked in github.
COPY ./custom/modules ${TMP_DRUPAL_BUILD_DIR}/custom_modules
COPY ./custom/themes ${TMP_DRUPAL_BUILD_DIR}/custom_themes

# Tests
COPY ./tests/behat.yml ${TMP_DRUPAL_BUILD_DIR}/behat.yml
COPY ./tests/features ${TMP_DRUPAL_BUILD_DIR}/features
