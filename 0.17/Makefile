CNAME=factorio_server
BRANCH=latest

all: clean $(CNAME)

$(CNAME):
	docker build -t $(CNAME):$(BRANCH) .

clean:
	docker stop $(CNAME) || true
	docker rm $(CNAME) || true
	docker rmi $(CNAME):$(BRANCH) || true

run:
	docker run -d -it --network host -v /opt/factorio:/factorio --name $(CNAME) --restart=always $(CNAME):$(BRANCH) --update

log:
	docker logs $(CNAME)
