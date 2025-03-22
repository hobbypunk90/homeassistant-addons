#!/usr/bin/env bashio

mkdir -p /config/step
ln -s /config/step /root/.step

if ! [ -f /config/last_options.json ]; then
  touch /config/last_options.json
fi

bashio::config.require 'password'

echo "Debug: $(bashio::config 'debug')"

if [ "" = "" ]; then
  export STEPDEBUG=1
fi

echo $(bashio::config 'password') > /tmp/password_file

if [ ! -f /root/.step/config/ca.json ] || ! diff /config/options.json /config/last_options.json &>/dev/null; then
  rm -fr /config/step/*
  bashio::log.info 'Initialize step ca ...'

  hostname=$(bashio::host.hostname)
  network_info=$(bashio::network)
  ip_addresses=$(echo ${network_info} | jq '[ [.interfaces[]] | .[].ipv4.address[] ] | join(",")' | tr -d '"')

  bashio::log.info $(step ca init --name "${hostname}" \
                                  --dns "$(hostname),${hostname},${ip_addresses}" \
                                  --provisioner "homeassistant@${hostname}" \
                                  --address ":9000" \
                                  --password-file /tmp/password_file >/dev/null)
  
  step-ca --password-file /tmp/password_file /root/.step/config/ca.json >/dev/null &
  sleep 2
  bashio::log.info $(step ca token --password-file /tmp/password_file "${hostname}" >/config/token)
  killall step-ca

  bashio::log.info $(step ca provisioner add homeassistant --type ACME)
  cp /config/options.json /config/last_options.json
fi

fingerprint=$(cat /config/step/config/defaults.json | grep fingerprint | sed 's/.*"fingerprint": "//; s/",//')
bashio::log.info "Root fingerprint: ${fingerprint}"
bashio::log.info "Root token: $(cat /config/token)"

bashio::log.info "Root certificate:"
cat /config/step/certs/root_ca.crt
cp  /config/step/certs/root_ca.crt $(bashio::config 'root_ca_path')

bashio::log.info "Intermediate certificate:"
cat /config/step/certs/intermediate_ca.crt

bashio::log.info 'Start step ca ...'
step-ca --password-file /tmp/password_file /root/.step/config/ca.json
