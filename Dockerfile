#
FROM alpine:3.15 AS base

RUN apk update \
    && apk upgrade \
    && apk add --update --no-cache \
        bash \
        curl \
        sudo

# aws cli のインストールは実行しない
# 必要なファイルは work ディレクトリに置いてある想定とする
# RUN pip3 install awscli

# ログインシェルやユーザ周り
ARG LOGIN_SHELL=/bin/bash
ENV SHELL ${LOGIN_SHELL}
#
ARG USERNAME=dev
ARG HOME=/home/${USERNAME}
WORKDIR ${HOME}
#
ARG USER_UID=100
ARG GRUOPNAME=wheel
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN adduser -S ${USERNAME} -h ${HOME} -s ${SHELL} -u ${USER_UID} -G ${GRUOPNAME} \
    && echo "%${GRUOPNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
USER ${USERNAME}

# jq のインストール
## バイナリをダウンロードして、パスに追加（シンボリックリンクを貼る）
ARG BIN_DIR=${HOME}/.local/bin
RUN mkdir -p ${BIN_DIR} \
    && curl -sSL https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -o ${BIN_DIR}/jq \
    && chmod +x ${BIN_DIR}/jq \
    && sudo ln -s /home/dev/.local/bin/jq /usr/local/bin/jq

# 必要なファイルは work ディレクトリに置かれる前提で COPY する
COPY ./work ${HOME}/work
# 動作確認に必要なファイルを COPY する
COPY ./filter.conf ${HOME}/filter.conf

# コンテナ起動時にシェルスクリプトを実行する
CMD [ "./work/sandbox.sh" ]