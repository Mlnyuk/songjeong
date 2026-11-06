# 송정 한바퀴

기존 Kubernetes `songjeong/songjeong-web`에서 추출한 정적 웹사이트입니다. HTML, CSS, JavaScript가 `site/index.html` 하나에 들어 있으며 DB, API 서버, API 키, npm 빌드가 필요하지 않습니다.

## 일반 서버: Docker Compose

Docker Engine과 Docker Compose 플러그인이 설치된 서버에서 실행합니다.

```bash
git clone https://github.com/Mlnyuk/songjeong.git
cd songjeong
docker compose up -d --build
```

접속 주소는 `http://서버IP:8080`입니다. 서버 방화벽에서 사용할 포트를 허용하세요. 다른 포트는 `PORT=80 docker compose up -d --build`로 지정합니다. 로컬에서만 열려면 `BIND_ADDRESS=127.0.0.1`을 함께 지정합니다. 도메인과 HTTPS는 대상 환경의 리버스 프록시에서 설정합니다.

Compose가 없는 서버에서는 다음 명령으로 실행할 수 있습니다.

```bash
docker build -t songjeong-web:local .
docker run -d --name songjeong-web --restart unless-stopped \
  --read-only --tmpfs /tmp:rw,noexec,nosuid,size=64m,mode=1777 \
  --cap-drop ALL --security-opt no-new-privileges:true \
  -p 8080:8080 songjeong-web:local
```

## 다른 Kubernetes 클러스터

대상 클러스터의 kubeconfig와 네임스페이스/Deployment/Service/ConfigMap 생성 권한이 필요합니다. 공개 Nginx 이미지에 접근할 수 있어야 합니다. 별도 이미지 빌드나 사설 레지스트리는 필요 없습니다.

```bash
git clone https://github.com/Mlnyuk/songjeong.git
cd songjeong
kubectl config get-contexts
bash scripts/deploy-k8s.sh YOUR_TARGET_CONTEXT
```

스크립트는 지정한 context에만 배포하며 현재 context를 바꾸지 않습니다. `YOUR_TARGET_CONTEXT`를 새 클러스터 이름으로 바꾸세요. 생성되는 namespace는 `songjeong`입니다.

```bash
# 할당된 NodePort 확인: http://접근가능한노드IP:NODEPORT
kubectl --context YOUR_TARGET_CONTEXT -n songjeong get svc songjeong-web

# NodePort 접근이 불가능한 환경에서 로컬 확인
kubectl --context YOUR_TARGET_CONTEXT -n songjeong port-forward svc/songjeong-web 8080:80
```

노드 고정, 클러스터 IP, 기존 NodePort 번호를 포함하지 않습니다. 새 클러스터가 사용 가능한 NodePort를 할당합니다. 고정 포트가 필요하면 `deploy/k8s/service.yaml`의 `ports` 항목에 사용 가능한 `nodePort`를 추가하세요. 클라우드 LoadBalancer를 쓰려면 서비스 `type`을 `LoadBalancer`로 변경하세요. Ingress를 연결할 경우 서비스 `type`을 `ClusterIP`로 변경하고 Ingress의 backend를 `songjeong-web:80`으로 지정합니다.

HTML 수정 후 같은 배포 명령을 실행하면 Kustomize가 ConfigMap 이름의 해시를 바꾸어 새 Pod를 배포합니다. 롤백에 쓰는 이전 ConfigMap은 자동 삭제하지 않습니다.

## 정적 호스팅 또는 파일 배포

`site/`의 내용만 웹서버의 document root에 복사하면 됩니다. 정적 호스팅에서는 빌드 명령 없이 게시 디렉터리를 `site`로 지정합니다. 카카오맵은 외부 링크로 열리며 API 키가 필요하지 않습니다.

로컬 미리보기:

```bash
python3 -m http.server 8080 --bind 127.0.0.1 --directory site
```

## 검증

```bash
bash scripts/smoke-test.sh
kubectl kustomize . > /tmp/songjeong.yaml
docker compose config --quiet
```

smoke test는 임시 컨테이너를 로컬 인터페이스에만 띄워 HTTP 응답과 원본 HTML이 바이트 단위로 같은지 검사하고 컨테이너를 정리합니다. GitHub Actions에서도 Docker 실행 검사, Compose 검증, Kubernetes 렌더링을 수행하며 완성된 YAML을 artifact로 제공합니다. Actions는 운영 클러스터에 자동 배포하지 않습니다.

## 이전 원본

- 추출일: 2026-11-06 UTC
- 출처: namespace `songjeong`, ConfigMap `songjeong-html`, key `index.html`
- 원본 크기: 21,928 bytes
- 원본 SHA-256: `d94cc7fbb2a464b050430f86cbfa2ef1c1e6ec64ec19ab834d030757344af6f2`
- HTML 원본은 수정하지 않았습니다. 장소 데이터는 기존 화면에 표시된 대로 MVP 예시 데이터입니다.

기존 서비스는 유지한 채 새 환경에서 확인한 후 도메인/접속 주소를 전환할 수 있습니다. 별도로 이전할 DB나 업로드 파일은 없습니다.

런타임은 [비루트 Nginx 이미지](https://github.com/nginx/docker-nginx-unprivileged)의 검증된 digest에 고정했습니다. 이미지 업데이트 시 Dockerfile과 Kubernetes Deployment의 digest를 함께 변경하고 smoke test를 실행하세요. 배포 구성은 [Kubernetes Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)를 사용합니다.
