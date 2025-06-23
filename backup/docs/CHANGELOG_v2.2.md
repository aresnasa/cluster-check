# Kubernetes集群健康检查工具 v2.2 更新日志

## 🎉 v2.2版本发布 (2025-05-27)

### 核心改进

#### 1. 智能状态提取系统 ✨
- **多格式兼容**: 支持多种HTML状态格式识别
- **准确状态检测**: 正确识别成功/警告/失败状态
- **实时汇总**: 自动统计健康节点数量和集群健康率

```bash
# 状态识别示例
系统检查: <span class="status success">成功</span>  → OK
系统检查: <span class="status warning">警告</span>  → WARNING  
系统检查: <span class="status error">失败</span>    → FAILED
```

#### 2. 历史文件智能清理 🧹
- **按主机分组**: 自动识别相同主机的不同版本报告
- **保留最新**: 基于文件修改时间保留最新版本
- **清理重复**: 删除旧格式和重复文件

```bash
# 清理示例
🗑️ 删除旧版本: cpu_worker_check_report_k8s-cpu-worker-01.html
✅ 保留最新: cpu_worker_check_report_k8s-cpu-worker-01_192.168.1.30.html
```

#### 3. 远程临时文件清理 🔧
- **自动清理**: 每个节点检查完成后自动清理远程临时文件
- **可控清理**: 通过`cleanup_temp_files`变量控制清理行为
- **分类清理**: 分别清理HTML报告文件和检查脚本

```yaml
# Playbook清理任务示例
- name: "清理Master节点的临时文件"
  shell: |
    # 清理远程生成的HTML报告文件
    rm -f {{ results_dir }}/*master*check*.html
    # 清理远程检查脚本
    rm -f "{{ check_script_path }}"
  when: cleanup_temp_files | default(true) | bool
```

#### 4. Bash版本兼容性 🛠️
- **临时文件映射**: 使用临时文件替代关联数组
- **跨版本支持**: 支持bash 3.x和4.x+版本
- **稳定性提升**: 避免bash版本差异导致的错误

```bash
# 兼容性改进
# 修复前: 使用关联数组(需要bash 4.0+)
declare -A host_files

# 修复后: 使用临时文件(兼容bash 3.x+)
local temp_mapping="/tmp/host_files_$$"
```

### 技术优化

#### 状态提取函数优化
```bash
# 系统检查状态匹配
if grep -q "系统检查:.*success.*成功\|系统检查:.*<span.*success.*成功" "$report_file"; then
    echo "OK"
elif grep -q "系统检查:.*warning.*警告\|系统检查:.*<span.*warning.*警告" "$report_file"; then
    echo "WARNING"
elif grep -q "系统检查:.*error.*失败\|系统检查:.*<span.*error.*失败" "$report_file"; then
    echo "FAILED"
else
    echo "UNKNOWN"
fi
```

#### 清理逻辑优化
```bash
cleanup_old_reports() {
    local source_dir="$1"
    local temp_mapping="/tmp/host_files_$$"
    
    # 使用临时文件存储主机文件映射
    # 比较文件时间戳，删除旧版本
    # 清理临时文件
}
```

### 配置更新

#### inventory_unified.ini
```ini
# 新增清理控制变量
cleanup_temp_files=true

# 修复语法错误
check_memory_usage=true  # 之前: check_memory_usage=trueba sh
```

#### Makefile更新
```makefile
# 新增清理标签支持
check-master-only:
    @ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml \
        --tags "p1_master_setup,p1_master_check,p1_master_fetch,p1_master_cleanup,..."
```

### 测试验证

#### 端到端测试
1. **状态识别测试**: 创建多种状态的测试文件，验证状态提取正确性
2. **清理功能测试**: 验证远程和本地文件清理功能
3. **完整流程测试**: 演示模式端到端测试成功

#### 测试结果
```bash
📊 集群统计: 总节点 17, 健康 13, 警告 2, 异常 2
⚠️ 警告: 集群健康率较低 (76%)，请检查异常节点
✅ 统一报告已生成: ./report/unified_cluster_report.html
```

### 性能改进

- **减少文件冗余**: 自动清理重复和过期文件
- **优化内存使用**: 使用临时文件而非内存关联数组
- **提升执行效率**: 精确的正则表达式匹配
- **增强稳定性**: 兼容更多bash版本

### 向后兼容性

- ✅ 完全兼容v2.1配置文件
- ✅ 保持现有命令接口不变
- ✅ 支持现有报告格式
- ✅ 维护原有功能特性

## 🚀 升级指南

### 从v2.1升级到v2.2
1. 无需修改配置文件
2. 重新运行检查即可享受新功能
3. 建议清理旧的报告文件以体验清理功能

### 新用户快速开始
```bash
# 克隆或更新代码后
make check  # 运行演示模式测试
```

## 🔧 故障排除

### 状态显示UNKNOWN
- 检查HTML报告格式是否匹配
- 验证状态提取正则表达式
- 查看generate_unified_report.sh中的extract_status函数

### 清理功能不工作
- 检查`cleanup_temp_files`变量设置
- 验证文件权限
- 查看playbook执行日志

## 📋 下一步计划

1. **GUI界面开发**: 基于Web的报告查看界面
2. **监控集成**: 支持Prometheus/Grafana集成
3. **告警系统**: 异常状态自动告警
4. **历史趋势**: 支持历史数据分析

---
**发布日期**: 2025年5月27日  
**版本**: v2.2.0  
**兼容性**: bash 3.x+, Ansible 2.9+
