# D1 - GitOps & CI/CD With ArgoCD

Lab nay thuc hanh GitOps tren Minikube bang ArgoCD, GitHub Actions va mot app nginx don gian.

## Muc tieu

- Cai ArgoCD tren Minikube.
- Tao app nginx bang Kubernetes manifest.
- Luu desired state trong Git repo.
- Chay GitHub Actions validate manifest khi Pull Request.
- Sau khi merge, thay doi image tag hoac manifest trong Git.
- De ArgoCD sync app vao cluster.
- Tao drift bang cach sua truc tiep tren cluster voi `kubectl`.
- Quan sat ArgoCD bao `OutOfSync`.
- Rollback dung `git revert`.
- Thu `kubectl rollout undo` va giai thich vi sao khong phai GitOps rollback.

## Cau truc

```text
d1-gitops-cicd/
  README.md
  manifests/
    kustomization.yaml
    namespace.yaml
    deployment.yaml
    service.yaml
  argocd/
    application.yaml
  ../../.github/
    workflows/
      validate-d1-pr.yaml
```

## 1. Chuan bi Minikube

```bash
minikube start
kubectl get nodes
```

## 2. Cai ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server
```

Lay admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath='{.data.password}' | base64 -d
```

Mo UI:

```bash
kubectl -n argocd port-forward svc/argocd-server 8080:443
```

Truy cap `https://localhost:8080`, user la `admin`.

## 3. Tao GitOps application

Sua `argocd/application.yaml`:

- Doi `repoURL` thanh URL GitHub repo cua ban.
- Giu `path: labs/week2/d1-gitops-cicd/manifests` neu repo nay duoc push nguyen cau truc.

Apply ArgoCD Application:

```bash
kubectl apply -f argocd/application.yaml
kubectl -n argocd get applications
```

Sync app:

```bash
argocd app sync nginx-gitops
```

Neu khong cai ArgoCD CLI, co the sync tren ArgoCD UI.

Kiem tra app:

```bash
kubectl -n d1-gitops get deploy,svc,pod
```

## 4. Validate manifest khi Pull Request

Workflow `.github/workflows/validate-d1-pr.yaml` se chay khi Pull Request thay doi file trong `labs/week2/d1-gitops-cicd`.

Workflow gom:

- `kubectl kustomize labs/week2/d1-gitops-cicd/manifests`
- Kiem tra schema/server-side co the chay local khi da co Minikube

Trong GitHub-hosted runner thuong khong co cluster Kubernetes, vi vay lab nay mac dinh render manifest offline bang Kustomize. Neu muon validate day du hon, chay lenh sau tren may local khi Minikube dang chay:

```bash
kubectl apply --dry-run=server -f manifests
```

## 5. Cap nhat image tag hoac manifest sau merge

Tao branch moi, sua image trong `manifests/deployment.yaml`, vi du:

```yaml
image: nginx:1.27.4
```

Mo Pull Request, doi workflow pass, sau do merge vao branch chinh.

ArgoCD se phat hien Git thay doi. Neu Application khong bat auto-sync, bam `Sync` tren UI hoac chay:

```bash
argocd app sync nginx-gitops
```

## 6. Tao drift bang kubectl

Sua live state truc tiep tren cluster:

```bash
kubectl -n d1-gitops set image deployment/nginx nginx=nginx:1.26.3
kubectl -n d1-gitops rollout status deployment/nginx
```

Quan sat tren ArgoCD:

- Desired state trong Git van la image cu.
- Live state trong cluster da bi sua bang `kubectl`.
- App se thanh `OutOfSync`.

Sync lai tu ArgoCD de dua cluster ve dung Git:

```bash
argocd app sync nginx-gitops
```

## 7. Rollback bang git revert

Neu commit moi lam app loi, rollback dung Git:

```bash
git log --oneline
git revert <commit_sha>
git push
```

Sau khi revert duoc merge/push vao branch chinh, ArgoCD sync cluster ve desired state moi trong Git.

## 8. Thu kubectl rollout undo

Chay:

```bash
kubectl -n d1-gitops rollout undo deployment/nginx
kubectl -n d1-gitops rollout status deployment/nginx
```

Giai thich:

- `kubectl rollout undo` chi sua live state trong cluster.
- Git repo khong doi.
- Voi GitOps, Git la source of truth.
- ArgoCD se thay cluster khac Git va bao `OutOfSync`.
- Khi sync, ArgoCD co the dua Deployment quay lai dung manifest trong Git.

Ket luan: rollback dung `git revert` moi la GitOps rollback. `kubectl rollout undo` chi nen dung de cuu tam thoi, sau do van phai cap nhat Git.
