setup-dns: 
	@echo "Setting up DNS..."
	@sudo mkdir -p /etc/systemd/system/docker.service.d 
	@sudo cp docker.service /etc/systemd/system/docker.service.d 
	@sudo service docker restart
	@docker run -d -p 172.17.0.1:53:53/udp --name skydns crosbymichael/skydns -nameserver 8.8.8.8:53 -domain tomgeorge.com
	@docker run -d -v /var/run/docker.sock:/docker.sock --name skydock crosbymichael/skydock -ttl 30 -environment dev -s /docker.sock -domain tomgeorge.com -name skydns

redis-volume: 
	@echo "Creating redis persistent storage..."
	@docker run  -d --name=redis-volume  redis-volume

run: setup-dns 
	@echo "Starting cluster..."
	@docker run -d --name redis1 --volumes-from=redis-volume redis redis-server --appendonly yes
	@docker run -d --name redis2 --volumes-from=redis-volume redis redis-server --appendonly yes
	@docker run -d --name redis3 --volumes-from=redis-volume redis redis-server --appendonly yes
	@docker run -d --name redis4 --volumes-from=redis-volume redis redis-server --appendonly yes

start-cluster:
	@echo "Starting cluster..."
	@docker run -d --name redis1 --volumes-from=redis-volume redis redis-server --appendonly yes
	@docker run -d --name redis2 --volumes-from=redis-volume redis redis-server --appendonly yes
	@docker run -d --name redis3 --volumes-from=redis-volume redis redis-server --appendonly yes
	@docker run -d --name redis4 --volumes-from=redis-volume redis redis-server --appendonly yes

stop-cluster:
	@echo "Stopping cluster..."
	@docker stop redis1 redis2 redis3 redis4
	@docker rm redis1 redis2 redis3 redis4

stop:
	@echo "Stopping cluster..."
	@docker stop redis1 redis2 redis3 redis4
	@docker stop skydock
	@docker stop skydns

clean: stop
	@echo "Removing images..."
	@docker rm redis1 redis2 redis3 redis4
	@docker rm skydock
	@docker rm skydns

clean-data: clean
	@echo "Removing redis volume..."
	@docker rm -v redis-volume
