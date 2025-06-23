# Kubernetes集群健康检查工具 v2.2

## 🎯 功能概述

本工具提供**两种报告模式**的Kubernetes集群健康检查：

- **详细模式** (`detailed`): 生成完整的HTML报告，包含详细的系统信息、配置详情和诊断数据
- **简要模式** (`simple`): 生成简洁的报告，只显示检查项的通过/失败状态，便于快速查看

支持多种输出格式：HTML、文本和Markdown，并保留完整的Ansible批量执行能力。

## ✨ v2.2版本特性

### 双模式报告系统
- **详细HTML报告**: 包含完整的系统信息、配置详情、命令输出
- **简要状态报告**: 只显示通过/失败状态，支持HTML和Markdown格式
- **统一入口脚本**: 通过参数选择不同的报告模式和输出格式

### 增强的数据目录检查
- 自动检查kubelet、containerd、docker和etcd数据目录位置
- 警告数据目录位于/home下的潜在问题
- 支持动态获取docker数据目录路径

### 灵活的执行选项
- 支持生产环境和演示环境切换
- 可选择特定节点类型进行检查
- 支持Ansible tags精确控制检查范围

## 🚀 快速开始

### 1. 环境准备

```bash
# 安装Ansible
pip install ansible

# 确保SSH连接正常 (生产环境)
ssh-copy-id user@your-k8s-nodes

# 克隆或下载项目
git clone <repository>
cd cluster-check
```

### 2. 配置inventory

编辑 `inventory_unified.ini` 文件，配置您的集群节点：

```ini
# 生产环境配置
[k8s_masters]
master-node-1 ansible_host=192.168.1.10 ansible_user=root

[k8s_cpu_workers]  
cpu-worker-1 ansible_host=192.168.1.20 ansible_user=root

[k8s_gpu_workers]
gpu-worker-1 ansible_host=192.168.1.30 ansible_user=root

# 演示环境配置 (使用localhost)
[k8s_masters_demo]
localhost ansible_connection=local ansible_user=$USER

[k8s_cpu_workers_demo]
localhost ansible_connection=local ansible_user=$USER

[k8s_gpu_workers_demo]
localhost ansible_connection=local ansible_user=$USER
```

### 3. 执行检查

#### 基础用法

```bash
# 生成详细HTML报告 (默认模式)
./cluster_check.sh

# 生成简要HTML报告
./cluster_check.sh --mode simple

# 生成简要Markdown报告
./cluster_check.sh --mode simple --format markdown

# 生成详细文本报告
./cluster_check.sh --mode detailed --format text
```

#### 高级用法

```bash
# 在生产环境生成简要报告
./cluster_check.sh --mode simple --env production

# 只检查Master节点并生成简要报告
./cluster_check.sh --mode simple --tags "p1_master_check"

# 只检查Worker节点
./cluster_check.sh --mode simple --tags "p2_cpu_worker_check,p3_gpu_worker_check"

# 使用自定义inventory文件
./cluster_check.sh --mode simple --inventory my_inventory.ini

# 查看所有选项
./cluster_check.sh --help
```

## 📊 报告类型对比

### 详细模式 (detailed)
- **适用场景**: 深度诊断、问题排查、详细审计
- **内容**: 完整系统信息、配置文件内容、命令输出
- **优点**: 信息全面、便于分析问题
- **缺点**: 文件较大、信息量多

### 简要模式 (simple)  
- **适用场景**: 快速状态检查、日常监控、批量检查
- **内容**: 检查项通过/失败状态
- **优点**: 简洁明了、快速查看、便于统计
- **缺点**: 缺少详细信息

## 🔍 检查项目说明

### 通用检查项
- **系统配置**: Cgroup版本、防火墙状态、SELinux状态
- **Kubernetes基础**: Swap禁用、时区配置、时间同步
- **软件包**: kubelet、kubectl、kubeadm安装状态
- **容器运行时**: Docker、Containerd状态
- **数据目录**: 关键数据目录位置检查

### Master节点专用
- **Kubernetes组件**: kube-apiserver、kube-controller-manager、kube-scheduler
- **etcd**: 集群数据存储状态
- **etcd数据目录**: etcd数据存储位置检查

### GPU Worker节点专用  
- **NVIDIA驱动**: GPU驱动和内核模块状态
- **NVIDIA工具**: nvidia-smi可用性
- **DCGM**: 数据中心GPU管理器状态

## 📁 输出结构

```
cluster-check/
├── cluster_check_results/          # 各节点检查结果
│   ├── hostname_master_check_*.html
│   ├── hostname_cpu_worker_check_*.html
│   └── hostname_gpu_worker_check_*.html
└── report/                         # 统一报告
    ├── unified_cluster_report.html
    └── simplified_cluster_report.md   # 简要Markdown报告
```

## ⚙️ 配置选项

### 命令行参数

| 参数 | 选项 | 默认值 | 说明 |
|------|------|--------|------|
| `-m, --mode` | detailed/simple | detailed | 报告模式 |
| `-f, --format` | html/text/markdown | html | 输出格式 |
| `-e, --env` | demo/production | demo | 执行环境 |
| `-t, --tags` | ansible标签 | 无 | 限制检查范围 |
| `-i, --inventory` | 文件路径 | inventory_unified.ini | Inventory文件 |
| `-p, --playbook` | 文件路径 | unified_cluster_check_playbook_v2.yml | Playbook文件 |

### 环境变量

在模板中可以使用以下环境变量：
- `OUTPUT_FORMAT`: 输出格式
- `SIMPLIFIED_REPORT`: 是否为简化报告模式
- `NODE_TYPE`: 节点类型
- `NODE_NAME`: 节点名称

## 🛠️ 高级功能

### 1. 自定义检查脚本

可以编辑 `templates/` 目录下的模板文件来自定义检查项：
- `master_check_script.sh.j2`: Master节点检查模板
- `cpu_worker_check_script.sh.j2`: CPU Worker检查模板  
- `gpu_worker_check_script.sh.j2`: GPU Worker检查模板

### 2. 批量执行

使用Ansible的并行执行能力：
```bash
# 并行执行所有节点检查
./cluster_check.sh --mode simple --env production

# 分组执行
./cluster_check.sh --mode detailed --tags "p1_master_check"
./cluster_check.sh --mode detailed --tags "p2_cpu_worker_check,p3_gpu_worker_check"
```

### 3. 自动化集成

可以将工具集成到CI/CD流水线或定时任务中：
```bash
# 定时检查脚本示例
#!/bin/bash
./cluster_check.sh --mode simple --format markdown --env production
# 将结果发送到监控系统或通知渠道
```

## 🧪 测试和验证

### 快速测试

```bash
# 运行测试脚本验证配置
./test_setup.sh

# 使用演示模式测试
./cluster_check.sh --mode simple --env demo
```

### 故障排除

1. **Ansible连接问题**:
   ```bash
   # 测试连接
   ansible all -i inventory_unified.ini -m ping
   ```

2. **权限问题**:
   ```bash
   # 确保脚本可执行
   chmod +x cluster_check.sh
   chmod +x generate_simplified_markdown_report.sh
   ```

3. **依赖检查**:
   ```bash
   # 检查Ansible版本
   ansible-playbook --version
   
   # 验证inventory语法
   ansible-inventory -i inventory_unified.ini --list
   ```

## 📝 开发和贡献

### 文件结构
```
cluster-check/
├── cluster_check.sh                # 主入口脚本
├── test_setup.sh                   # 测试脚本
├── inventory_unified.ini           # 统一配置文件
├── unified_cluster_check_playbook_v2.yml  # 主Playbook
├── generate_simplified_markdown_report.sh  # Markdown报告生成器
└── templates/                      # 检查脚本模板
    ├── master_check_script.sh.j2
    ├── cpu_worker_check_script.sh.j2
    └── gpu_worker_check_script.sh.j2
```

### 添加新的检查项

1. 编辑相应的模板文件
2. 在简化模式中添加状态提取逻辑
3. 更新Markdown报告生成器的状态检查函数
4. 测试新功能

## 📋 更新日志

### v2.2 (2025-06-23)
- ✨ 新增双模式报告系统 (详细/简要)
- ✨ 新增数据目录位置检查功能
- ✨ 新增统一入口脚本支持多种参数
- ✨ 新增Markdown格式输出支持
- 🔧 优化Ansible playbook结构
- 🔧 改进错误处理和用户体验

### v2.1
- GPU Worker节点DCGM完整集成
- 智能报告状态提取
- 历史文件自动清理

### v2.0  
- 统一配置管理
- 多节点类型支持
- HTML汇总报告

## 📞 支持

如有问题或建议，请：
1. 检查本文档的故障排除部分
2. 运行 `./test_setup.sh` 验证配置
3. 查看生成的报告获取详细错误信息

---

**Kubernetes集群健康检查工具 v2.2** - 让集群健康检查变得简单高效！
