#!/bin/sh

handler() {
    VERSION=$(cat << EOL
=== LIBRARY VERSION ===
- $(aws --version)
- $(jq --version)
- $(curl --version)
EOL
    )
    echo "${VERSION}" 1>&2;


    YESTERDAY=$(date "+%Y/%m/%d" --date '1 day ago')
    aws s3 cp s3://"${BUCKET}"/"${YESTERDAY}" . --recursive

    # BLOCK
    BLOCK=$(find . -name "aws-*" -print0 \
        | xargs --null jq 'select(.action == "BLOCK") | {uri: .httpRequest.uri}' \
        | grep -v "}" | grep -v "{" | grep -c "${GREP}")

    # ALLOW
    ALLOW=$(find . -name "aws-*" -print0 \
        | xargs --null jq 'select(.action == "ALLOW") | {uri: .httpRequest.uri}' \
        | grep -v "}" | grep -v "{" \
        | grep -vf /tmp/filter.conf \
        | sort | uniq | awk '{print $2}' | sed -e 's/\"//g')

    LOG=$(cat << EOL
=== LOG ===
- DATE:${YESTERDAY}
- BUCKET:${BUCKET}
- files:$(find . -name "aws-*" | wc -l)
- BLOCKs:${BLOCK}
- ALLOWs:${ALLOW}
EOL
    )
    echo "${LOG}" 1>&2;

    curl -X POST -H 'Content-type: application/json' -d "{\"text\":\"${ALLOW}\"}" "${SLACK_WEBHOOK_URL}"
}