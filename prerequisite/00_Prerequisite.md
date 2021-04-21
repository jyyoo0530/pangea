# MicroService한 AI Engineering Prototyping 환경 구축

## 준비사항
1. 노트북 2대

|용도|사양|접속정보|
|------|---|---|
|Master|CPU: 16core 2.2GHz // MEM: 24GB<br>HDD: 200GB // OS: Ubuntu Focal<br>|-IP: 172.17.106.76 // -Hostname : master<br>|
|Worker|CPU: 8core 1.8GHz // MEM: 16GB<br>HDD: 150GB // OS: Ubuntu Focal<br>|-IP: 172.17.106.56 // -Hostname : node-clt<br>|

2. 외부 인터넷 접속 가능
    - 클러스터 구성에 사용된 모든 제품이 오픈소스이며, 클러스터 자체가 외부 서비스에 노출되어야 하는 점을 근거
    - ping 8.8.8.8 (구글) 응답 오면 됨
3. 서버에 대한 root 권한
    - 클러스터 자체가 인프라 성격을 띄고 있어 서버의 많은 부분을 직접 터치해야 하므로 로트 계정 필요
    - 예) 서버 포트 관리(서버 네트워크 설정 변경), `systemctl` 설정 변경 `etc`폴더 내에 값 변경 등
4. 엔드유저를 위해 서버 도메인 필요