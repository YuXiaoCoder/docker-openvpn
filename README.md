## OpenVPN

### 环境

+ `OS`: `CentOS 7.8`
+ `Docker`：`19.03.8`
+ `Docker Compose`：`1.26.0`

### 部署

+ 拷贝代码：

```bash
rsync -azPS --delete --exclude="*.git*" docker-openvpn VPN:/root/
```

+ 构建镜像：

```bash
cd /root/docker-openvpn
docker build --no-cache --tag docker-openvpn .
```

+ 启动容器：

```bash
docker-compose up -d
```

+ 添加路由：

```bash
iptables -t nat -L
iptables -t nat -A POSTROUTING -s 10.8.0.0/16 -o eth0 -j MASQUERADE
```

+ 进入容器：

```bash
docker exec -it openvpn bash
```

### 使用

+ 导出客户端配置：

```bash
docker run --rm -v /data/openvpn:/etc/openvpn docker-openvpn dump_client_config.sh > client.ovpn
```

***
