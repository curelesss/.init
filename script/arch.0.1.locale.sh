#!/usr/bin/env bash
# Edit /etc/locale.gen → uncomment en_US.UTF-8 and zh_CN.UTF-8 if needed
# Then run locale-gen only if changes were actually made

set -u
set -e

LOCALE_FILE="/etc/locale.gen"
CHANGED=0

# Check if file exists and is writable
if [[ ! -f "$LOCALE_FILE" ]]; then
    echo "Error: ${LOCALE_FILE} not found" >&2
    exit 1
fi

if [[ ! -w "$LOCALE_FILE" ]]; then
    echo "Error: Need root privileges to edit ${LOCALE_FILE}" >&2
    echo "Try: sudo $0"
    exit 1
fi

# Uncomment en_US.UTF-8 if commented
if grep -q "^# *en_US\.UTF-8 UTF-8" "$LOCALE_FILE"; then
    sed -i 's/^# *\(en_US\.UTF-8 UTF-8\)/\1/' "$LOCALE_FILE"
    CHANGED=1
    echo "Uncommented en_US.UTF-8"
elif grep -q "^en_US\.UTF-8 UTF-8" "$LOCALE_FILE"; then
    echo "en_US.UTF-8 already uncommented"
else
    echo "Warning: en_US.UTF-8 line not found in ${LOCALE_FILE}"
fi

# Uncomment zh_CN.UTF-8 if commented
if grep -q "^# *zh_CN\.UTF-8 UTF-8" "$LOCALE_FILE"; then
    sed -i 's/^# *\(zh_CN\.UTF-8 UTF-8\)/\1/' "$LOCALE_FILE"
    CHANGED=1
    echo "Uncommented zh_CN.UTF-8"
elif grep -q "^zh_CN\.UTF-8 UTF-8" "$LOCALE_FILE"; then
    echo "zh_CN.UTF-8 already uncommented"
else
    echo "Warning: zh_CN.UTF-8 line not found in ${LOCALE_FILE}"
fi

# Only run locale-gen if we actually made changes
if (( CHANGED == 1 )); then
    echo "Running locale-gen..."
    if locale-gen; then
        echo "Locale generation completed successfully"
    else
        echo "locale-gen failed" >&2
        exit 1
    fi
else
    echo "No changes needed - locales already configured"
fi

exit 0
