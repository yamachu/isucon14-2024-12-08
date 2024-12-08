# >() がbashじゃないと使えないので
SHELL=/bin/bash
# Issue番号は用途によって分けているけど、とりあえずDB周りは1
ISSUE=1

# https://github.com/cli/cli/blob/trunk/docs/install_linux.md#official-sources
gh:
	type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
	&& echo "deb [arch=$$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
	&& sudo apt update \
	&& sudo apt install gh -y

# isucon11qの接続パラメータであるため、今後いい感じにする
mysql/client:
	@mysql -h 127.0.0.1 -P 3306 -u isucon isuride -pisucon

# echoを見せているのは、どんなクエリ投げたっけを見るためにしてる
mysql/query: QUERY=
mysql/query:
	echo "$(QUERY)" | $(MAKE) mysql/client

mysql/query/gh: QUERY=
mysql/query/gh:
	$(MAKE) mysql/query QUERY="$(QUERY)" | tee >(gh issue comment $(ISSUE) -F -)
