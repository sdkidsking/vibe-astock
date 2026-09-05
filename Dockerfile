# A股短线复盘看板 —— 单容器全家桶（server.py + frontend/dist + vr/）
# 前端产物由本地 npm run build 后随仓库一起同步进来（deploy skill 部署前会验证编译），
# 镜像里不装 node，保持体积和构建时间可控。

FROM python:3.12-slim

# libstdc++6：mini-racer 的 V8 二进制依赖；tzdata：zoneinfo("Asia/Shanghai") 需要时区库
# （slim 基础镜像不带；代码里 china_today() 显式取上海时区，不依赖容器 TZ，但日志时间会用到）
# 换腾讯云内网 apt 源：deb.debian.org 在国内龟速（三进制 sources 文件格式为 trixie 默认，
# 旧版 bookworm 是 sources.list——两条都兜住）
RUN set -eux; \
    [ -f /etc/apt/sources.list.d/debian.sources ] \
      && sed -i 's|deb.debian.org|mirrors.cloud.tencent.com|g; s|security.debian.org|mirrors.cloud.tencent.com/debian-security|g' /etc/apt/sources.list.d/debian.sources \
      || sed -i 's|deb.debian.org|mirrors.cloud.tencent.com|g; s|security.debian.org|mirrors.cloud.tencent.com/debian-security|g' /etc/apt/sources.list; \
    apt-get update \
    && apt-get install -y --no-install-recommends libstdc++6 tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 依赖层单独先行：requirements.txt 不变时命中缓存，不重复 pip install。
# PIP_INDEX_URL 由 compose 传入（国内构建走腾讯云 pypi 镜像，快且稳）
ARG PIP_INDEX_URL=https://mirrors.cloud.tencent.com/pypi/simple
COPY requirements.txt ./
RUN pip install --no-cache-dir -i "$PIP_INDEX_URL" -r requirements.txt

# 代码 + 前端产物（配合 .dockerignore 排除 .venv/node_modules 等）
COPY . .

# 运行时数据（~/.duanxian-agents、~/.vibe-research）全部重定向到 /data 挂卷持久化，
# 绝不写进镜像层。HOME 重定向是因为代码里数据目录硬编码 expanduser("~")
ENV HOME=/data \
    TZ=Asia/Shanghai \
    PYTHONUNBUFFERED=1
RUN mkdir -p /data

EXPOSE 8910

# ⚠️ 不用 `python server.py`：那边 uvicorn.run 硬编码绑 127.0.0.1，容器端口映射不通。
# 路由装配（VR 并入、安全闸、涨停池日期钉住）都在 import 时完成，与原启动方式等价。
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8910"]
