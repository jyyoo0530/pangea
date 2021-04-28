# CI/CD Pipeline 구축

## 1. ARGO CD
Argo CD 는 version 2.0.0-rc1 이상을 사용해야한다. 아니면 kubectl 을 apply로만 해서 길이 제한때문에 kafka-operator 배포가 안되는 문제 발생.
https://github.com/argoproj/argo-cd/issues/5704

#### a. 준비
```aidl
kubectl create namespace devops
cd /kubernetes
ARGO=./cicd/argo
VERSION=2.0.0-rc1
mkdir -p $ARGO
```

#### b. ArgoCD 설치
ArgoCD 설치 yaml 다운로드
```aidl
curl -o $ARGO/argo-install.yaml https://raw.githubusercontent.com/argoproj/argo-cd/v$VERSION/manifests/install.yaml
sed -i 's/namespace: argocd/namespace: devops/g' $ARGO/argo-install.yaml
```
master node에만 배포를 하기 위하여, `nano $ARGO/argo-install.yaml`에서 4개의 `deployment`(`argocd-dex-server`,`argocd-redis`,`argocd-repo-server`,`argocd-server`) 및 1개의 `statefulSet`(`argocd-application-controller`)
에 대해 `affinity`항목에 다음 사항을 추가한다.
```aidl
nano $ARGO/argo-install.yaml
```
```aidl
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/role
                operator: In
                values:
                - master
```

ArgoCD 적용
```aidl
kubectl apply -f $ARGO/argo-install.yaml -n devops
```

Nodeport way
```aidl
cat <<EOF > $ARGO/argo-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: argocd-server-external
  labels:
    app.kubernetes.io/component: server
    app.kubernetes.io/name: argocd-server
    app.kubernetes.io/part-of: argocd
spec:
  type: NodePort
  ports:
    - port: 443
      targetPort: 8080
      protocol: TCP
      name: http
      nodePort: 30000
  selector:
    app.kubernetes.io/name: argocd-server
EOF
kubectl apply -f $ARGO/argo-nodeport.yaml -n devops
```

c. password 확인 및 접속
```aidl
kubectl -n devops get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo
```
위 결과물이 암호이다.