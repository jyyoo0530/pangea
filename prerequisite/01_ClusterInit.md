# 서버 기초환경 구성

## 1. 서버 네트워크 설정 변경
우선 root 권한 확보.<br>
```sudo su```

```aidl
export PATH=$PATH:/usr/local/bin
```

#### a. 서버 호스트 네임 등록
```aidl
cat <<EOF >> /etc/hosts
172.17.106.76 master
172.17.106.56 node-clt
EOF
```
각 서버에 노드들의 호스트 네임이 등록되어 있지 않으면 서로 커뮤니케이션을 못하는 경우가 발생

#### b. 포트 오픈 설정

아래 포트가 오픈되어 있어야 함.

|노드|포트|TCP/UDP|
|------|---|---|
|Master|6443, 2379-2380, 10250, 10251, 10252|TCP|
|Master,Worker|6783, 6784|TCP|
|Worker|10250, 30000-32767|TCP|
|Load Balancer|26443|TCP|

아래 스크립트로 포트 오픈<br>

MasterNode에 대해 다음 포트 오픈
```aidl
iptables -I INPUT 1 -p tcp --dport 6443 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 2379 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 2380 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 10250 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 10251 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 10252 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 6783 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 26443 -j ACCEPT
```

WorkerNode에 대해 다음 포트 오픈
```aidl
iptables -I INPUT 1 -p tcp --dport 6783 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 30000-32767 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 10250 -j ACCEPT
iptables -I INPUT 1 -p tcp --dport 26443 -j ACCEPT
```

#### d. 스왑 메모리 해제
```aidl
swapoff -a && sed -i '/ swap / s/^/#/' /etc/fstab
```
논란이 많은 부분이지만, 쿠버네티스 공식문서에서 설명하기를, 쿠버네티스의
모티브가 주어진 자원을 효율적으로 활용한다 이기때문에, swap은 고려하지 않는다고 한다.

#### e. Iptables 커널 옵션 활성화
```aidl
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
echo '1' > /proc/sys/net/ipv4/ip_forward
```
RHEL이나 CentOS7 사용시 iptables가 무시되서 트래픽이 잘못 라우팅되는 문제가 발생한다고 하여 아래 설정이 추가됨

#### f. 쿠버네티스 리포지터리 yum 추가 <<<<<여기부터
```aidl
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

yum -y update
```

## 2. 도커 / 쿠버네티스 설치
#### a. 도커 설치
```aidl
yum install -y https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-19.03.11-3.el7.x86_64.rpm \
https://download.docker.com/linux/centos/7/x86_64/stable/Packages/containerd.io-1.4.4-3.1.el7.x86_64.rpm \
https://download.docker.com/linux/centos/7/x86_64/stable/Packages/docker-ce-cli-20.10.5-3.el7.x86_64.rpm \
http://mirror.centos.org/centos/7/extras/x86_64/Packages/container-selinux-2.107-3.el7.noarch.rpm
```
쿠버네티스 공식 문서에서 권장하는 도커 버젼과 실제 도커 최신버젼은 차이가 있으니 확인.
2021-03-25 현재 19.03 버젼 권장하고 있음.
```aidl
mkdir /etc/docker

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  }
// xfs 파일시스템의 경우 ftype=1이어야 overlay2 사용가능.
// 현재 상암 서버의 경우, ftype=0으로 아래 옵션 사용불가.
// 잠재적 문재를 일으킬 것으로 예상되나, 아직 문제 식별되지 않음.
//  ,
//  "storage-driver": "overlay2",
//  "storage-opts": [
//    "overlay2.override_kernel_check=true"
//  ]
}
EOF

mkdir -p /etc/systemd/system/docker.service.d
```
cgroup을 systemd로 변경하고 적용.
#### b. docker 서비스 시작
```
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
```

#### c. 쿠버네티스 설치
```aidl
yum install -y --disableexcludes=kubernetes kubeadm-1.20.4-0.x86_64 kubectl-1.20.4-0.x86_64 kubelet-1.20.4-0.x86_64
```
쿠버네티스는 버젼에 민감함. `kubeadm` & `kubectl` & `kubelet`의 버젼은 항상 동일하게 유지하도록 함.


## 3. 기타 소프트웨어 설치
#### a. helm(필수)
```aidl
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 > get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
rm -f get_helm.sh
```
b. nano(옵션)
```aidl
yum install nano -y
```

# GPU 서버 세팅
## 1. 기초환경
기본적인 docker 및 kubeadm, kubelet, kubectl은 구성되어 있다는 가정으로 시작한다.

### A. install nvidia-docker2
#### a. add apt repo list
```sh
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# apt repository update & install package
apt-get update
apt-get list nvidia-docker2
```

#### b. install nvidia-docker2
```sh
apt-get install -y nvidia-docker2
```
> 설치 진행 중간에 `/etc/docker/daemon.json`을 교체 할건지에 대해 물어 본다.  
> Default 설정인 N를 선택하여, 이후에 해당 파일을 직접 수정하여 docker 서비스를 재시작하는것을 권장한다.(특히 컨테이너가 기동되고 있는 상태에서는 Drain이후에 진행하는것을 권장)

기존 `/etc/docker/daemon.json` 파일에 아래와 같은 내용을 추가하고, docker 서비스를 재시작하면 된다.
```json
  "default-runtime": "nvidia",
  "runtimes": {
    "nvidia": {
      "path": "nvidia-container-runtime",
      "runtimeArgs": []
    }
  }
```

```sh
# docker service restart
systemctl restart docker
```

#### c. nvidia-smi test
docker내에서 gpu를 사용하기 위해서는 위해서는 적절한 Nvidia Driver와 CUDA버전의 확인이 필요하다.  
자세한 내용은 [Nvidia container toolkit install guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#platform-requirements)를 참고하면 좋다.
```sh
nvidia-smi
# result example
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 440.64.00    Driver Version: 440.64.00    CUDA Version: 10.2     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
...
```

docker에서 CUDA를 통한 GPU 활용을 위해 다음과 같은 docker image를 사용하게 될 경우 적정한 CUDA버전의 지정이 필요하다.  
앞서 살펴본 CUDA버전의 원하는 docker image를 Nvidia CUDA 공식 [Docker Hub](https://hub.docker.com/r/nvidia/cuda)에서 이미지를 받을 수 있다.

특정 버전의 이미지를 통해서 다음과 같이 동일한 테스트를 할 수 있다.
```sh
docker run --rm --gpus all nvidia/cuda:10.2-base nvidia-smi
```

위에서 테스트한 이미지는 cuda version 10.2의 base 이미지를 사용하였고, Version 및 OS와 수행 목적에 따라 다양한 이미지를 제공해주고 있다.

자세한 nvidia docker 사용법은 다음 [가이드](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/user-guide.html)를 참고하면 된다.