local tested. <br>
confirm following etherever node. <br>
well viewing blockscout about etherever. <br>

<br>
docker-compose.yml   <br>
backend <br>
ETHEREUM_JSONRPC_TRACE_URL: ""  <br>

docker update --cpus 0.5 $(docker compose ps -q)  <br>
<br>
# 컨테이너를 강제로 재생성하여 설정을 덮어씁니다.
docker-compose up -d --force-recreate backend
<br>
docker-compose rm -f -s -v backend
<br>
docker-compose up -d backend
<br>
