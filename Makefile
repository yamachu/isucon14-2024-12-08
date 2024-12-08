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

slowlog:
	pt-query-digest <(sudo cat /var/log/mysql/mysql-slow.log) | tee >(gh issue comment $(ISSUE) -F -)
	sudo truncate /var/log/mysql/mysql-slow.log --size 0

sync/mysqld.cnf:
	sudo cp ./etc/mysqld.cnf /etc/mysql/conf.d/mysqld.cnf

edit/my.cnf:
	sudo vi /etc/mysql/conf.d/mysqld.cnf

restart/mysql:
	sudo systemctl restart mysql

restart/go:
	sudo systemctl restart isuride-go.service

restart/node:
	sudo systemctl restart isuride-node.service

switch/go:
	sudo systemctl disable --now isuride-node.service
	sudo systemctl enable --now isuride-go.service

switch/node:
	sudo systemctl disable --now isuride-go.service
	sudo systemctl enable --now isuride-node.service

jlog/go:
	sudo journalctl -xu isuride-go

jlog/node:
	sudo journalctl -xu isuride-node
