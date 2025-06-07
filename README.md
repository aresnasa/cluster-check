# Kubernetes集群健康检查工具 v2.2 - 完整文档

## 🎉 v2.2版本新特性

### 核心改进
1. **统一配置管理** - 单一inventory_unified.ini文件支持生产和演示环境
2. **优化的工作流程** - copy本地模板 → 远程执行 → 结果回传 → 本地汇总
3. **完整的DCGM集成** - GPU Worker节点包含完整的NVIDIA DCGM监控功能
4. **智能报告分类** - 自动按节点类型分类和重命名报告文件
5. **统一HTML表格报告** - 生成清晰的汇总表格，支持状态标识和排序

### ✨ v2.2版本重大更新
1. **智能状态提取** - 汇总脚本现在能正确识别HTML报告中的状态信息（成功/警告/失败）
2. **历史文件清理** - 自动清理重复文件，按主机分组保留最新版本报告
3. **远程临时文件清理** - Playbook执行完成后自动清理远程生成的临时文件
4. **improved报告格式** - 支持多种HTML格式状态提取，兼容性更强
5. **完整端到端测试** - 包含完整的演示模式测试流程
6. **bash版本兼容性** - 使用临时文件替代关联数组，支持更多bash版本

### 清理功能
- **远程清理**: 每个节点检查完成后自动清理远程临时文件
- **本地清理**: 汇总时自动删除历史重复文件，保留最新版本
- **可控清理**: 通过`cleanup_temp_files`变量控制清理行为

### 文件架构

```
cluster-check/
├── inventory_unified.ini           # 统一inventory配置文件 (新)
├── unified_cluster_check_playbook_v2.yml  # v2版本playbook (新)
├── generate_unified_report.sh      # 统一报告生成脚本
├── Makefile                        # 更新了v2命令
├── templates/                      # 脚本模板目录
│   ├── master_check_script.sh.j2
│   ├── cpu_worker_check_script.sh.j2
│   └── gpu_worker_check_script.sh.j2
├── cluster_check_results/          # 从远程节点回传的原始报告
└── report/                        # 最终处理后的报告目录
    ├── MASTER_*.html
    ├── CPU_WORKER_*.html
    ├── GPU_WORKER_*.html
    └── unified_cluster_report.html # 统一汇总报告
```

## 🚀 快速开始

### 1. 演示模式 (推荐)
```bash
# 使用v2版本进行本地演示 (使用localhost模拟)
make check
# 或者
make demo
```

### 2. 生产环境
```bash
# 编辑inventory_unified.ini，配置实际节点信息
# 然后运行生产环境检查
make prod
```

## 📋 配置说明

### inventory_unified.ini结构

```ini
# 生产环境配置
[k8s_masters]
master-node-1 ansible_host=192.168.1.10 ansible_user=root node_name=master-node-1

[k8s_cpu_workers]
cpu-worker-1 ansible_host=192.168.1.20 ansible_user=root node_name=cpu-worker-1

[k8s_gpu_workers]
gpu-worker-1 ansible_host=192.168.1.30 ansible_user=root node_name=gpu-worker-1 gpu_type=nvidia-v100

# 演示环境配置
[k8s_masters_demo]
localhost ansible_connection=local ansible_user=$USER node_name=master-demo-1

[k8s_cpu_workers_demo]
localhost ansible_connection=local ansible_user=$USER node_name=cpu-worker-demo-1

[k8s_gpu_workers_demo]
localhost ansible_connection=local ansible_user=$USER node_name=gpu-worker-demo-1 gpu_type=nvidia-demo

# 全局变量
[all:vars]
ansible_python_interpreter=auto
kubectl_version=v1.28.0
cleanup_temp_files=true
remote_results_dir=/tmp/cluster_check_results
local_results_dir=./cluster_check_results
local_report_dir=./report
```

## 🔄 工作流程详解

### v2版本工作流程
1. **模板复制** - 使用copy模块将本地templates/*.j2文件复制到远程节点
2. **模板处理** - 在远程节点使用sed进行变量替换，生成可执行脚本
3. **远程执行** - 在远程节点执行健康检查脚本，生成HTML报告
4. **结果回传** - 使用fetch模块将远程HTML报告回传到本地cluster_check_results/
5. **本地汇总** - 在本地对报告进行分类、重命名，并生成统一汇总报告

### 报告分类逻辑
```bash
# 原始文件: localhost_Frank-MacBook-Pro.local_master_check_20250527_153719.html
# 重命名为: MASTER_20250527_153719_20250527_153737.html

# 原始文件: localhost_Frank-MacBook-Pro.local_cpu_worker_check_20250527_153731.html  
# 重命名为: CPU_WORKER_20250527_153731_20250527_153736.html

# 原始文件: localhost_Frank-MacBook-Pro.local_gpu_worker_check_20250527_153734.html
# 重命名为: GPU_WORKER_20250527_153734_20250527_153736.html
```

## 📊 报告系统

### 报告类型
1. **详细节点报告** - 每个节点生成独立的HTML报告
2. **统一汇总报告** - unified_cluster_report.html，包含所有节点的表格化汇总

### 统一汇总报告特点
- **表格化展示** - 清晰的HTML表格格式
- **状态标识** - ✅健康、⚠️警告、❌异常
- **智能状态提取** - 自动从详细报告中提取关键状态信息
- **响应式设计** - 现代化CSS样式，支持排序和筛选

## 🛠️ 可用命令

### 主要命令
```bash
make check              # v2演示模式 (推荐，使用localhost模拟)
make demo               # 同 check 命令 (演示模式)
make prod               # v2生产模式 (连接实际节点)
make show-reports       # 显示并打开最新报告
```

### 辅助命令
```bash
make clean              # 清理所有临时文件和报告
make version            # 显示版本信息
make install-deps       # 安装依赖（macOS）
```

## 🎮 GPU和DCGM监控

### DCGM功能特性
v2版本包含完整的NVIDIA DCGM (Data Center GPU Manager) 监控：

1. **DCGM服务检查** - 检查dcgm-exporter服务状态
2. **群组信息** - 显示DCGM群组配置
3. **字段组信息** - 显示监控字段配置
4. **健康检查** - GPU健康状态诊断
5. **实时监控** - GPU利用率、温度、功耗等指标

### GPU类型支持
- nvidia-v100
- nvidia-a100  
- nvidia-rtx4090
- nvidia-demo (演示模式)

## 🔧 故障排除

### 常见问题

#### 1. SSH连接问题
```bash
# 检查inventory配置
cat inventory_unified.ini

# 测试SSH连接
ansible -i inventory_unified.ini k8s_masters -m ping
```

#### 2. 模板处理问题
```bash
# 检查模板文件
ls -la templates/

# 手动验证模板语法
ansible-playbook --syntax-check unified_cluster_check_playbook_v2.yml
```

#### 3. 报告生成问题
```bash
# 检查生成脚本权限
ls -la generate_unified_report.sh

# 手动运行报告生成
./generate_unified_report.sh ./report
```

### 调试模式
```bash
# 使用verbose模式查看详细输出
ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml -vvv
```

## 📈 性能特点

### 并发执行
- Master节点: serial=3 (最多3个并发)
- CPU Worker: serial=5 (最多5个并发)  
- GPU Worker: serial=3 (最多3个并发)

### 错误处理
- 使用ignore_errors确保单节点失败不影响整体流程
- 智能状态提取，处理部分失败的检查结果

## 🔮 升级指南

### 从v1升级到v2
1. 备份现有配置: `cp inventory.ini inventory.ini.backup`
2. 使用新的统一配置: `cp inventory_unified.ini inventory.ini` (可选)
3. 测试v2演示模式: `make check`
4. 迁移到生产环境: `make prod`

### 配置迁移
v1的inventory.ini可以继续使用，但建议迁移到inventory_unified.ini以获得更好的管理体验。

## 💡 最佳实践

1. **首先运行演示模式** - 确保工具正常工作
2. **定期检查** - 建议每日或每周运行检查
3. **查看统一报告** - 优先查看unified_cluster_report.html
4. **保留历史报告** - 定期备份report目录
5. **监控DCGM** - 确保GPU节点的DCGM服务正常运行

---

## 📞 支持信息

- **版本**: v2.0.0
- **支持的系统**: Linux (生产), macOS (开发/演示)
- **Ansible版本**: 2.10+
- **Python版本**: 3.6+

如有问题，请查看生成的日志文件或运行verbose模式获取详细信息。
