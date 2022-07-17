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

    # # ALLOW
    # ALLOW=$(find . -name "aws-*" -print0 \
    #     | xargs --null jq 'select(.action == "ALLOW") | {uri: .httpRequest.uri}' \
    #     | grep -v "}" | grep -v "{" | grep -c "${GREP}")

    # ALLOW
    # この grep -v をパイプラインで繋ぐのは改修したい
    # 外部ファイルに切り出す方法を試したが、Lambda 上だと切り出したファイルが見つからないとなってしまった
    ALLOW=$(find . -name "aws-*" -print0 \
        | xargs --null jq 'select(.action == "ALLOW") | {uri: .httpRequest.uri}' \
        | grep -v "}" | grep -v "{" \
        | grep -v '/_static/[0-9]*/sentry/*' \
        | grep -v '/api/[0-9]/*' \
        | grep -v '/api/v1/*' \
        | grep -v '/buyer/*' \
        | grep -v '/css/*' \
        | grep -v '/favicon.ico' \
        | grep -v '/index.html' \
        | grep -v '/isfw_assets/*' \
        | grep -v '/manager/*' \
        | grep -v '/manual/*' \
        | grep -v '/privacy.html' \
        | grep -v '/terms.html' \
        | grep -v '/trust-dx-sentry/*' \
        | grep -v '/logo_reaas_128.png' \
        | sort | uniq)

    WAFLOG=$(cat << EOL
=== WAF LOG ===
- DATE:${YESTERDAY}
- BUCKET:${BUCKET}
- files:$(find . -name "aws-*" | wc -l)
- BLOCKs:${BLOCK}
- ALLOWs:${ALLOW}
EOL
    )
    echo "${WAFLOG}" 1>&2;
}