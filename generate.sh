#!/bin/sh

# constants ##################################################################

# line separated domain names
DOMAIN_SOURCE="https://data.iana.org/TLD/tlds-alpha-by-domain.txt"

# directory in which to store our build files
# this allows us to only release a new version when these files change
CACHE_DIR=cache
YARN_BIN=yarn
# a respectful delay in seconds to wait between queries so as to not spam IANA
RESPECTFUL_DELAY=1

# globals ####################################################################
# json to output
json='{}'
# current domain index
current=0

# main #######################################################################

mkdir -pv "${CACHE_DIR}"

## fetch #####################################################################

printf "[i] %s\n" "fetching domain list..."

# get the updated domains file
wget -qO- "$DOMAIN_SOURCE" | tail -n+2 >"${CACHE_DIR}/domains" || exit 1

total="$(wc -l "${CACHE_DIR}/domains" | cut -d' ' -f1)"

# fetch the whois of all domains in our domain file
while read -r line; do
	current="$((current + 1))"

	# skip comments
	[ "${line##\#*}" ] || continue

	printf "[i] %s" "($current/$total) fetching $line"

	server="$(
		whois -h whois.iana.org "$line" |
			grep whois: |
			tr -d '[:space:]' |
			cut -d: -f2 2>/dev/null
	)"

	# some servers come empty
	if [ -z "$server" ]; then
		printf " - %s\n" "empty"
		continue
	fi

	printf " - %s\n" "ok"

	njson="$(
		# add the new server to our output
		printf "%s\n" "$json" |
			jq \
				'. + {$domain: $server}' \
				--arg domain "$(
					printf "%s\n" "$line" |
						tr '[:upper:]' '[:lower:]'
				)" \
				--arg server "$server"
	)"

	json="$njson"

	sleep "${RESPECTFUL_DELAY}"

done <"${CACHE_DIR}/domains"

## generation ################################################################

printf "%s\n" "$json" >"${CACHE_DIR}/servers.new.json"

if [ ! -e "${CACHE_DIR}/servers.json" ] ||
	[ -n "$(
		diff "${CACHE_DIR}/servers.new.json" "${CACHE_DIR}/servers.json"
	)" ]; then

	printf "[i] %s\n" "changes pending"

	mv "${CACHE_DIR}/servers.new.json" "${CACHE_DIR}/servers.json"

	printf "[i] %s" "generating modules"
	printf "module.exports = %s\n" "$json" >lib/index.js
	printf "export default %s\n" "$json" >lib/index.mjs
	printf " - %s\n" "done"

	printf "[i] %s\n" "formatting code"
	"${YARN_BIN}" prettier
	printf "[i] %s\n" "all done"
else
	rm "${CACHE_DIR}/servers.new.json"
	printf "[i] %s\n" "no changes"
fi
