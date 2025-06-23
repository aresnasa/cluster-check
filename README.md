# Kubernetes 集群健康检查工具

这是一个用于批量检查Kubernetes集群健康状态的自动化工具。

## 快速使用

### 1. 配置主机清单

编辑 `inventory_unified.ini` 文件，配置要检查的节点信息。

### 2. 运行检查

```bash
# 详细检查报告（默认）
./cluster_check.sh

# 简化检查报告
./cluster_check.sh --report-type simplified

# 查看所有选项
./cluster_check.sh --help
```

### 3. 查看报告

- HTML报告：`cluster_check_results/` 目录
- Markdown报告：`report/` 目录

## 主要文件

- `cluster_check.sh` - 主入口脚本
- `unified_cluster_check_playbook_v2.yml` - Ansible playbook
- `inventory_unified.ini` - 主机清单配置
- `templates/` - 检查脚本模板
- `test_setup.sh` - 测试和验证脚本

## 环境要求

- Ansible 2.9+
- SSH密钥配置完成
- 目标节点具备相应权限

## 备注

详细文档和历史版本已移至 `backup/docs/` 目录。
