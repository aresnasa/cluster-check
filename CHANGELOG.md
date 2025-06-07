# Kubernetes集群健康检查工具 - 更新日志

## 版本 2.1.0 (2025-05-27)

### ✨ 新增功能

#### Master节点检查增强
- ✅ **etcd版本检查**: 添加了etcd服务状态、版本信息检查
- ✅ **etcd健康检查**: 支持etcd集群健康状态和成员列表检查
- ✅ **etcd Pod模式检测**: 自动检测和报告Static Pod模式的etcd
- ✅ **Master组件状态**: 检查kube-apiserver、kube-controller-manager、kube-scheduler状态
- ✅ **网络组件检查**: 自动检测CNI网络插件(Calico、Flannel、Weave等)

#### Worker节点系统配置完善
- ✅ **Cgroup版本检查**: 检测并建议Cgroup v1/v2版本
- ✅ **防火墙状态检查**: 检查Firewalld和UFW状态，确保符合K8s要求
- ✅ **SELinux状态检查**: 验证SELinux禁用状态
- ✅ **Swap状态检查**: 确保Swap已禁用
- ✅ **时区配置检查**: 验证时区设置为Asia/Shanghai
- ✅ **时间同步检查**: 检查Chronyd/NTP服务状态
- ✅ **Kubernetes内核参数**: 验证关键sysctl参数配置
- ✅ **Kubernetes软件包**: 检查kubelet、kubeadm、kubectl版本

#### GPU Worker节点专项增强
- ✅ **NVIDIA内核模块检查**: 验证NVIDIA驱动模块加载状态
- ✅ **DCGM完整支持**: 增强DCGM CLI、DCGM Exporter、Host Engine检查
- ✅ **GPU硬件检测**: 通过lspci检测显卡硬件
- ✅ **容器GPU支持**: 检查nvidia-docker、containerd GPU支持

### 🔧 改进功能

#### 报告格式增强
- ✅ **完整文本格式输出**: 所有节点类型都支持文本格式报告
- ✅ **状态标识优化**: 使用✅❌⚠️图标清晰标识检查状态
- ✅ **检查结果分类**: 按系统配置、软件包、组件状态等分类展示

#### 系统兼容性
- ✅ **多Linux发行版支持**: 改进操作系统检测兼容性
- ✅ **命令可用性检查**: 所有系统命令都有可用性验证
- ✅ **错误处理增强**: 命令执行失败时提供友好提示

### 📁 项目结构优化

#### 文件清理和重组
- 🗑️ **删除冗余文档**: 移除过时的标签说明和实现总结文档
- 🗑️ **清理临时文件**: 删除系统生成的.DS_Store文件
- 📋 **结构文档化**: 创建PROJECT_STRUCTURE.md详细说明项目组织

#### 模板文件完善
- 📝 **Master节点模板**: 完全重写master_check_script.sh.j2
- 📝 **CPU Worker模板**: 重新创建cpu_worker_check_script.sh.j2
- 📝 **GPU Worker模板**: 增强gpu_worker_check_script.sh.j2

### 🔍 检查项目详情

#### 系统配置检查 (所有节点)
```bash
# Cgroup版本
/sys/fs/cgroup/unified (v2) 或 /sys/fs/cgroup/memory (v1)

# 防火墙状态  
systemctl is-active firewalld
systemctl is-active ufw

# SELinux状态
getenforce

# Swap状态
swapon --show

# 时区配置
timedatectl show --property=Timezone

# 时间同步
systemctl is-active chronyd
systemctl is-active ntp

# 内核参数
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
vm.swappiness = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1
```

#### Master节点专项检查
```bash
# etcd检查
systemctl is-active etcd
etcd --version
kubectl get pods -n kube-system -l component=etcd
etcdctl endpoint health
etcdctl member list

# Master组件
kubectl get pods -n kube-system -l component=kube-apiserver
kubectl get pods -n kube-system -l component=kube-controller-manager  
kubectl get pods -n kube-system -l component=kube-scheduler

# 网络组件
kubectl get pods -n kube-system -l app=calico-node
kubectl get pods -n kube-system -l app=flannel
kubectl get pods -n kube-system -l app=weave-net
```

#### GPU Worker专项检查
```bash
# NVIDIA检查
nvidia-smi
lsmod | grep nvidia
lspci | grep -i "vga\|3d\|display"

# DCGM检查
dcgmi discovery -l
dcgmi group -l  
dcgmi fieldgroup -l
dcgmi diag -r 1
dcgmi dmon -e 155,203,204,251,252,1001,1002,1003,1004,1005 -c 3
dcgmi health -v
systemctl status nv-hostengine

# 容器GPU支持
nvidia-docker --version
containerd --version
```

### 🎯 使用方法

#### 执行完整检查
```bash
# 检查所有节点类型
ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml

# 仅检查Master节点
ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml --tags p1_master_check

# 仅检查CPU Worker节点  
ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml --tags p2_cpu_worker_check

# 仅检查GPU Worker节点
ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml --tags p3_gpu_worker_check
```

#### 生成统一报告
```bash
# 生成汇总报告
./generate_unified_report.sh

# 诊断和修复
./diagnose_and_fix.sh
```

### 📊 输出格式

#### HTML报告特性
- 🎨 现代化响应式设计
- 📱 移动端友好显示
- 🔍 详细的命令输出展示
- 🎯 状态颜色编码(绿色=正常，黄色=警告，红色=错误)
- 📈 资源使用情况图表

#### 文本报告特性  
- ✅ 清晰的状态图标
- 📋 分类组织的检查结果
- 🔍 关键信息摘要
- ⚡ 快速问题识别

### 🚀 性能优化

- ⚡ **并行执行**: Master节点并行度3，CPU Worker并行度5，GPU Worker并行度3
- 🔄 **错误容忍**: 单节点检查失败不影响其他节点
- 📦 **模板优化**: 远程生成脚本，减少网络传输
- 🧹 **自动清理**: 检查完成后自动清理临时文件

### 🛠️ 兼容性说明

#### 支持的操作系统
- CentOS 7/8/9
- RHEL 7/8/9  
- Ubuntu 18.04/20.04/22.04
- Debian 10/11/12

#### 支持的Kubernetes版本
- Kubernetes 1.20+
- 兼容kubeadm部署的集群
- 支持Static Pod和Systemd服务模式

#### 支持的GPU环境
- NVIDIA GPU + CUDA驱动
- NVIDIA Docker Runtime
- DCGM 2.0+ (可选)
- Containerd GPU支持

### 📝 注意事项

1. **权限要求**: 检查脚本需要sudo权限执行系统命令
2. **网络要求**: 需要访问Kubernetes API Server
3. **DCGM可选**: DCGM不是必需的，但建议GPU节点安装以获得更好的监控
4. **etcdctl配置**: etcd健康检查可能需要证书配置

### 🔗 相关文档

- [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) - 项目结构说明
- [README.md](./README.md) - 使用指南
- [inventory_unified.ini](./inventory_unified.ini) - 节点配置示例
