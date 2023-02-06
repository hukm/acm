#!/bin/sh
set -e

# NEEDS THE FOLLOWING VARS IN ENV:
# DOMAIN
# CLOUDFLARE_EMAIL
# CLOUDFLARE_API_KEY
# HEROKU_API_KEY
# HEROKU_APP

# Only run once per week (Heroku scheduler runs daily) or if there are arguments
# This allows passing --force to force a run
if [ "$(date +%u)" = 1 ] || [ "$#" -eq 1 ]
then
  # Download dependencies
  echo "Git clone"
  echo ""
  git clone https://github.com/Neilpang/acme.sh.git
  cd ./acme.sh

  echo "ACME install"
  echo ""
  # Force ensures it doesnt fail because of lack of cron
  ./acme.sh --install --force

  # Map to environment variables that the ACME script requires
  # export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
  # export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

  echo "Start certificate generation"
  # Generate wildcard certificate (this will take approx 130s)
  ~/.acme.sh/acme.sh --server letsencrypt --issue -d $DOMAIN  -d "*.$DOMAIN" -d "www.$DOMAIN"  --dns dns_aws

  # Update the certificate in the live app
  heroku certs:update "/app/.acme.sh/"$DOMAIN"_ecc/fullchain.cer" "/app/.acme.sh/"$DOMAIN"_ecc/$DOMAIN.key" --confirm $HEROKU_APP --app $HEROKU_APP
fi
