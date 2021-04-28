# K8S 클러스터 개시

## 1. Master서버에서 kubeadm 개시

#### a. kubeadm (master node만)

```aidl
rm -f ~/.kube/config
rm -f /etc/cni/net.d/*
rm -rf /var/lib/cni
rm -rf /var/lib/kubelet/*
systemctl restart kubelet
systemctl restart docker
kubeadm init --apiserver-advertise-address=$(hostname -I | cut -d' ' -f1) --pod-network-cidr=10.244.0.0/16
```

마지막에 출력되는 `kubeadm join ~~`은 출력해서 따로 보관한다. 그리고 `kubectl`명령어를 위해 아래를 수행한다.

```aidl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

컨트롤 플레인이 정상적으로 마무리 될때 까지 기다린다

```aidl
kubectl wait pod/kube-controller-manager-master --for=condition=Ready --timeout=300s -n kube-system
```

#### b. flannel operator 설치

Kubernetes는 pod간 통신을 위해 다양한 3rd party plugin을 제공하고 있는데, 그 중 flannel을 사용한다.(Calico도 많이씀)

```aidl
mkdir -p ./podoperator/flannel
curl -o ./podoperator/flannel/flannel.yaml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
kubectl apply -f ./podoperator/flannel/flannel.yaml
```

#### c. node join

각각의 노드에서 join command를 실행한다.

```aidl
rm -f ~/.kube/config
rm -f /etc/cni/net.d/*
rm -rf /var/lib/cni
rm -rf /var/lib/kubelet/*
systemctl restart kubelet
systemctl restart docker
kubeadm join xxx.xxx.xxx.xxx:6443 --token {token} --discovery-token-ca-cert-hash {discovery-token}
```

#### d. cluster 작동상태 확인

```aidl
kubectl get nodes
```

결과가 모두 아래와 같이 ready이면 준비 완료

```aidl
NAME         STATUS   ROLES                  AGE   VERSION
node-clt     Ready    <none>                 13m   v1.20.4
master       Ready    control-plane,master   14m   v1.20.4
```

#### e. taint 해제
Master노드의 taint 상황 확인
```aidl
kubectl describe node master | grep Taints
```
Master노드에 클러스터 운영을 위한 추가 Pod을 구성하기 위해 Taint 해제한다.
```aidl
kubectl taint nodes --all node-role.kubernetes.io/master-
```

좀더 명확한 노드관리를 위해 각 노드에 role 부여
```aidl
kubectl label --overwrite nodes master kubernetes.io/role=master
kubectl label --overwrite nodes node-clt kubernetes.io/role=node-clt
```