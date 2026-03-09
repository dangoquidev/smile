#! /bin/bash
set -e

here="$(realpath "$(dirname "${0}")")"
cd "${here}"

for sufix in e n ne nw s se sw w; do
	cp --force "menu_c.png" "menu_${sufix}.png"
done
