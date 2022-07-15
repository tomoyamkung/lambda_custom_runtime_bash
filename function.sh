function handler() {
    echo "=== LIBRARY VERSION ===" 1>&2;
    echo "- $(aws --version)" 1>&2;
    echo "- $(jq --version)" 1>&2;

    echo "=== WAF LOG ===" 1>&2;
    YESTERDAY=$(date "+%Y/%m/%d" --date '1 day ago')
    echo "- DATE:${YESTERDAY}" 1>&2;

    echo "- BUCKET:${BUCKET}" 1>&2;

    aws s3 cp s3://"${BUCKET}"/"${YESTERDAY}" . --recursive
    echo "- files:$(find . -name "aws-*" | wc -l)" 1>&2;

    # BLOCK
    echo -n "- BLOCKs:" 1>&2;
    echo $(find . -name "aws-*" | xargs jq 'select(.action == "BLOCK") | {uri: .httpRequest.uri}' \
        | grep -v "}" | grep -v "{" | grep "${GREP}" | wc -l)  1>&2;

    # ALLOW
    echo -n "- ALLOWs:" 1>&2;
    echo $(find . -name "aws-*" | xargs jq 'select(.action == "ALLOW") | {uri: .httpRequest.uri}' \
        | grep -v "}" | grep -v "{" | grep "${GREP}" | wc -l)  1>&2;

    # FILTER
    echo "- FILTERs:" 1>&2;
    # この grep -v をパイプラインで繋ぐのは改修したい
    # 外部ファイルに切り出す方法を試したが、Lambda 上だと切り出したファイルが見つからないとなってしまった
    echo $(find . -name "aws-*" | xargs jq 'select(.action == "ALLOW") | {uri: .httpRequest.uri}' \
        | grep -v "}" | grep -v "{" \
        | grep -v '/_static/[0-9]*/sentry/*' | grep -v '/api/[0-9]/*' | grep -v '/api/v1/*' \
        | grep -v '/buyer/*' | grep -v '/css/*' | grep -v '/favicon.ico' | grep -v '/index.html' \
        | grep -v '/isfw_assets/*' | grep -v '/manager/*' | grep -v '/manual/*' | grep -v '/privacy.html' \
        | grep -v '/terms.html' | grep -v '/trust-dx-sentry/*' | grep -v '/logo_reaas_128.png')  1>&2;
}