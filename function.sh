function handler() {
    echo "=== LIBRARY VERSION ===" 1>&2;
    echo "- "$(aws --version) 1>&2;
    echo "- "$(jq --version) 1>&2;

    echo "=== WAF LOG ===" 1>&2;
    YESTERDAY=$(date "+%Y/%m/%d" --date '1 day ago')
    echo "- DATE:${YESTERDAY}" 1>&2;

    echo "- BUCKET:${BUCKET}" 1>&2;

    aws s3 cp s3://"${BUCKET}"/"${YESTERDAY}" . --recursive
    echo "- files:"$(find . -name "aws-*" | wc -l) 1>&2;

    # BLOCK
    echo -n "- BLOCKs:" 1>&2;
    echo $(find . -name "aws-*" | xargs jq 'select(.action == "BLOCK") | {uri: .httpRequest.uri}' | grep -v "}" | grep -v "{" | grep "${GREP}" | wc -l)  1>&2;

    # ALLOW
    echo -n "- ALLOWs:" 1>&2;
    echo $(find . -name "aws-*" | xargs jq 'select(.action == "ALLOW") | {uri: .httpRequest.uri}' | grep -v "}" | grep -v "{" | grep "${GREP}" | wc -l)  1>&2;
}