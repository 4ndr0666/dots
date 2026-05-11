#!/bin/bash
# Author: 4ndr0666
# ======================= // SHELLART //
source_dir="/usr/share/archcraft/scripts/"
shellart_found=false

while IFS= read -r file; do 
    shellart_found=true
    exec "$file"
done < <(find "$source_dir" -type f)

if [ "$shellart_found" = false ]; then
    echo "Warning: No shell art scripts found in $source_dir."
fi
