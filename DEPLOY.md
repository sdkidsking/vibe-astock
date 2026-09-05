# 部署指南（LuffyTest 腾讯云轻量 + Docker + nginx 子路径）

线上地址：**https://7uffy.top/astock/**

架构：浏览器 → nginx（443，已有证书）→ `location /astock/` 剥前缀反代 → `127.0.0.1:8910`（容器，只绑回环，公网不可直达）。

前端构建时 `.env.production` 的 `VITE_BASE=/astock/` 让资源/路由/API 前缀自动适配；
后端收到的是剥掉前缀的原始路径，**零改动**。

## 日常更新（唯一要记的命令）

本地项目根目录：

```
/deploy ecs
```

deploy skill 自动：前端编译验证 → tar 同步（排除见 .deploy.yml）→ 远程智能构建 → `docker compose up -d`。
改了前端代码会自动带上新 dist；只改 Python 代码时远程构建命中缓存很快。

## 服务器现状（LuffyTest = 106.53.166.212，已实测）

- Ubuntu 24.04，4C/3.6G/40G（余量充足）；Docker 27.5.1 + Compose v2.32.4 已装
- 已在跑：ccswitch-webdav（8080）、nginx 两个静态站（7uffy.top / lu23.top）
- ⚠️ ubuntu 用户曾不在 docker 组（`docker ps` 假空），初始化时已修复，勿回退

## 首次部署做过的事（重做时参考）

```bash
# ① docker 权限（一次性，重新登录生效）
sudo usermod -aG docker ubuntu

# ② 项目目录与凭据
sudo mkdir -p /opt/apps/vibe-astock && sudo chown ubuntu /opt/apps/vibe-astock
#    /opt/apps/vibe-astock/.env —— MIMO_API_KEY 必填；VR_API_KEY 建议（chmod 600）

# ③ nginx 子路径反代（/etc/nginx/sites-available/7uffy.top 的 443 server 内加）：
location /astock/ {
    proxy_pass http://127.0.0.1:8910/;      # 结尾斜杠 = 剥掉 /astock 前缀
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;  # WebSocket 兼容
    proxy_set_header Connection "upgrade";
    proxy_buffering off;                     # AI 回答流式输出不卡
    proxy_read_timeout 600s;                 # 复盘跑图约 6 分钟，别中途掐断
}
#    然后 sudo nginx -t && sudo systemctl reload nginx

# ④ 定时复盘（crontab -e，收盘后自动跑，周末/节假日 preflight 自挡）
40 15 * * 1-5 docker exec vibe-astock python main.py >> /var/log/vibe-review.log 2>&1
```

防火墙：轻量控制台**不需要**放行 8910（容器只绑 127.0.0.1）；22 维持现状即可。

## 常见问题

| 症状 | 处理 |
|------|------|
| 打不开 404 | nginx 少了 `location /astock/`；`sudo nginx -t` 后 reload |
| 页面开但接口 403 | compose 的 `VIBE_ALLOW_HOSTS` 没带 7uffy.top（写操作 origin 闸） |
| 页面资源 404 | dist 是旧根路径版：本地重 `npm run build`（.env.production 在才带 /astock/）再 `/deploy ecs` |
| 复盘失败 MIMO_API_KEY | 服务器 `.env` 没配 / 没权限，`docker compose config` 看注入 |
| VR 分栏 401 | 设了 `VR_API_KEY` 后前端 设置页 也要填同一串（浏览器 localStorage） |
| 看容器日志 | `ssh LuffyTest "docker logs vibe-astock --tail 50"` |
