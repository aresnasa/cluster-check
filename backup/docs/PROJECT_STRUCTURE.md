# Kubernetes集群健康检查工具 - 项目结构

## 📁 项目目录结构

```
cluster-check/
├── 📄 配置文件
│   ├── ansible.cfg                              # Ansible配置文件
│   └── inventory_unified.ini                    # 统一清单配置文件
│
├── 📋 Playbook文件
│   ├── unified_cluster_check_playbook_v2.yml   # 主要playbook（完整流程）
│   └── play4_only.yml                          # 独立Play 4（仅汇总报告）
│
├── 🔧 脚本文件
│   ├── diagnose_and_fix.sh                     # 诊断和修复脚本
│   └── generate_unified_report.sh              # 统一报告生成脚本
│
├── 📚 文档文件
│   ├── README.md                               # 主要使用文档
│   └── PROJECT_STRUCTURE.md                   # 项目结构说明（本文件）
│
├── 🛠️ 构建文件
│   ├── Makefile                                # 简化的构建和运行文件
│   └── VERSION                                 # 版本信息文件
│
├── 📁 templates/                               # 模板文件目录
│   ├── cpu_worker_check_script.sh.j2          # CPU Worker节点检查脚本模板
│   ├── gpu_worker_check_script.sh.j2          # GPU Worker节点检查脚本模板
│   └── master_check_script.sh.j2              # Master节点检查脚本模板
│
├── 📁 cluster_check_results/                   # 原始检查结果目录（运行时生成）
│
└── 📁 report/                                  # 报告输出目录
    └── unified_cluster_report.html            # 统一汇总报告示例
```

## 🎯 文件分类说明

### 根目录核心文件
- **配置文件** (cfg, ini): Ansible和清单配置
- **Playbook文件** (yml): Ansible playbook脚本
- **脚本文件** (sh): Shell脚本工具
- **文档文件** (md): 项目文档和说明
- **构建文件**: Makefile和版本管理

### 专用目录
- **templates/**: 仅存放j2模板文件，用于生成远程执行脚本
- **cluster_check_results/**: 原始检查结果存储（临时目录）
- **report/**: 最终报告输出目录

## 🚀 核心功能文件

### 主要执行文件
1. `unified_cluster_check_playbook_v2.yml` - 完整集群检查流程
2. `play4_only.yml` - 独立汇总报告生成
3. `Makefile` - 简化的命令执行接口

### 配置文件
1. `inventory_unified.ini` - 集群节点配置
2. `ansible.cfg` - Ansible运行配置

### 工具脚本
1. `generate_unified_report.sh` - 统一报告生成工具
2. `diagnose_and_fix.sh` - 问题诊断和修复工具

## 📝 使用指南

1. **主要文档**: 查看 `README.md` 获取详细使用说明
2. **快速开始**: 使用 `make help` 查看可用命令
3. **配置**: 编辑 `inventory_unified.ini` 配置集群节点
4. **运行**: 使用 `make check-all` 执行完整检查

## 🏗️ 项目特点

- ✅ **结构清晰**: 按文件类型和功能分类组织
- ✅ **模板分离**: j2模板文件独立存放在templates目录
- ✅ **配置统一**: 所有配置文件在根目录便于管理
- ✅ **文档完善**: 包含完整的使用说明和结构文档
- ✅ **工具丰富**: 提供诊断、报告生成等辅助工具

---
*最后更新: 2025年5月27日*
