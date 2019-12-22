#!/bin/dash

# needs currency code as $1

GET() {
	check_net=$(curl -s -I -1 https://google.com)
	if [ -n "$check_net" ]; then
		echo $(curl -s --tlsv1.2 https://blockchain.info/ticker | sed -n /$1/p \
			| awk -F ':' '{ print $6 }' | cut -d ',' -f 1 | sed -n 's/^ //p')
	else
		echo "NaN"
	fi
}

PRINT() {
	printf '%.*f' 2 "$1"
}

price=$(GET $1)
PRINT $price
