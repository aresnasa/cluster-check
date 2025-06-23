#!/bin/bash

# ===========================================
# 简化版Markdown报告生成脚本
# 功能：从HTML报告提取关键检查项的通过/失败状态，生成简洁的Markdown报告
# 使用方法: ./generate_simplified_markdown_report.sh [源目录]
# ===========================================

echo "📝 Kubernetes集群简化Markdown报告生成工具"
echo "=============================================="

# 配置变量
SOURCE_DIR="${1:-./cluster_check_results}"
REPORT_DIR="./report"
OUTPUT_FILE="${REPORT_DIR}/simplified_cluster_report.md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 创建报告目录
mkdir -p "$REPORT_DIR"

# 检查源目录是否存在
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "❌ 错误: 源目录 $SOURCE_DIR 不存在"
    echo "请确保已运行集群检查并生成了检查结果"
    exit 1
fi

# 检查是否有HTML报告文件
html_files_count=$(find "$SOURCE_DIR" -name "*.html" -type f | wc -l)
if [[ $html_files_count -eq 0 ]]; then
    echo "❌ 错误: 在 $SOURCE_DIR 目录下没有找到HTML报告文件"
    echo "请先运行集群检查生成各节点的检查报告"
    exit 1
fi

echo "📁 源目录: $SOURCE_DIR"
echo "📁 输出目录: $REPORT_DIR" 
echo "📄 找到 $html_files_count 个HTML报告文件"

# 提取主要检查项状态的函数 (适配HTML报告格式)
extract_main_status() {
    local report_file="$1"
    local check_type="$2"
    
    if [[ ! -f "$report_file" ]]; then
        echo "❓"
        return
    fi
    
    case "$check_type" in
        "system")
            # 系统检查状态 - 匹配HTML中的实际内容
            if grep -q "系统检查:.*success.*成功\|系统检查:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "系统检查:.*error.*失败\|系统检查:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                echo "❌"
            elif grep -q "系统检查:.*warning.*警告\|系统检查:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                echo "⚠️"
            else
                echo "❓"
            fi
            ;;
        "kubernetes")
            # Kubernetes检查状态
            if grep -q "Kubernetes检查:.*success.*成功\|Kubernetes检查:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "Kubernetes检查:.*error.*失败\|Kubernetes检查:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                echo "❌"
            elif grep -q "Kubernetes检查:.*warning.*警告\|Kubernetes检查:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                echo "⚠️"
            elif grep -q "kubectl.*未找到" "$report_file" 2>/dev/null; then
                echo "N/A"
            else
                echo "❓"
            fi
            ;;
        "gpu")
            # GPU/DCGM检查状态
            if grep -q "GPU.*检查:.*success.*成功\|GPU.*检查:.*<span.*success.*成功\|DCGM.*检查:.*success.*成功\|DCGM.*检查:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "GPU.*检查:.*error.*失败\|GPU.*检查:.*<span.*error.*失败\|DCGM.*检查:.*error.*失败\|DCGM.*检查:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                echo "❌"
            elif grep -q "GPU.*检查:.*warning.*警告\|GPU.*检查:.*<span.*warning.*警告\|DCGM.*检查:.*warning.*警告\|DCGM.*检查:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                echo "⚠️"
            elif ! grep -q "GPU.*检查\|DCGM.*检查" "$report_file" 2>/dev/null; then
                echo "N/A"
            else
                echo "❓"
            fi
            ;;
        "resource")
            # 资源检查状态
            if grep -q "资源状态:.*success.*成功\|资源状态:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                echo "✅"
            elif grep -q "资源状态:.*warning.*警告\|资源状态:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                echo "⚠️"
            elif grep -q "资源状态:.*error.*失败\|资源状态:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                echo "❌"
            else
                echo "❓"
            fi
            ;;
        *)
            echo "❓"
            ;;
    esac
}

# 获取节点信息的函数
get_node_info() {
    local report_file="$1"
    local info_type="$2"
    
    case "$info_type" in
        "hostname")
            # 从文件名中提取主机名
            local filename=$(basename "$report_file" .html)
            if [[ "$filename" =~ _check_report_ ]]; then
                echo "$filename" | sed 's/.*_check_report_//'
            else
                echo "Unknown"
            fi
            ;;
        "node_type")
            # 基于文件名模式判断节点类型
            if [[ "$report_file" =~ master ]]; then
                echo "Master"
            elif [[ "$report_file" =~ gpu ]]; then
                echo "GPU Worker"
            else
                echo "CPU Worker"
            fi
            ;;
        "check_time")
            grep -o "时间: [^)]*" "$report_file" 2>/dev/null | cut -d' ' -f2- | head -1 || echo "Unknown"
            ;;
    esac
}

# 开始生成Markdown报告
echo "🔄 生成简化Markdown报告..."

cat > "$OUTPUT_FILE" << EOF
# Kubernetes集群健康检查报告 (简化版)

**生成时间**: $TIMESTAMP  
**报告类型**: 仅显示通过/失败状态的简化报告

---

## 📊 集群检查结果汇总

| 主机名 | 节点类型 | 系统检查 | Kubernetes | GPU/DCGM | 资源状态 | 整体状态 |
|--------|----------|----------|------------|-----------|----------|----------|
EOF

# 统计信息
total_nodes=0
healthy_nodes=0
warning_nodes=0
failed_nodes=0

# 处理每个HTML报告文件
for report_file in "$SOURCE_DIR"/*.html; do
    if [[ -f "$report_file" ]]; then
        # 提取主机名
        hostname=$(get_node_info "$report_file" "hostname")
        
        # 跳过可能的统一报告文件
        if [[ "$hostname" == "unified_cluster_report" || "$hostname" == "cluster_report" ]]; then
            continue
        fi
        
        total_nodes=$((total_nodes + 1))
        
        # 获取节点类型
        node_type=$(get_node_info "$report_file" "node_type")
        
        # 提取各项检查状态
        system_status=$(extract_main_status "$report_file" "system")
        k8s_status=$(extract_main_status "$report_file" "kubernetes")
        gpu_status=$(extract_main_status "$report_file" "gpu")
        resource_status=$(extract_main_status "$report_file" "resource")
        
        # 计算整体状态
        overall_status="✅"
        if [[ "$system_status" == "❌" || "$k8s_status" == "❌" || "$gpu_status" == "❌" || "$resource_status" == "❌" ]]; then
            overall_status="❌"
            failed_nodes=$((failed_nodes + 1))
        elif [[ "$system_status" == "⚠️" || "$k8s_status" == "⚠️" || "$gpu_status" == "⚠️" || "$resource_status" == "⚠️" ]]; then
            overall_status="⚠️"
            warning_nodes=$((warning_nodes + 1))
        else
            healthy_nodes=$((healthy_nodes + 1))
        fi
        
        # 生成表格行
        echo "| **$hostname** | $node_type | $system_status | $k8s_status | $gpu_status | $resource_status | $overall_status |" >> "$OUTPUT_FILE"
    fi
done

# 添加统计信息
cat >> "$OUTPUT_FILE" << EOF

---

## 📈 集群状态统计

- **总节点数**: $total_nodes
- **健康节点**: $healthy_nodes
- **警告节点**: $warning_nodes  
- **异常节点**: $failed_nodes
EOF

# 健康率计算
if [[ $total_nodes -gt 0 ]]; then
    health_rate=$(( (healthy_nodes * 100) / total_nodes ))
    echo "- **集群健康率**: ${health_rate}% ($healthy_nodes/$total_nodes)" >> "$OUTPUT_FILE"
fi
    fi
done

if [[ "$gpu_worker_found" == false ]]; then
    echo "| - | - | - | - | - | - | - | - | - | - | - | - | - |" >> "$OUTPUT_FILE"
fi

# 添加图例说明
cat >> "$OUTPUT_FILE" << 'EOF'

---

## 📖 状态图例

- ✅ **通过**: 检查项配置正确
- ❌ **失败**: 检查项存在问题，需要修复
- ⚠️ **警告**: 检查项可能存在潜在问题
- ❓ **未知**: 无法获取检查状态

## 🔍 检查项说明

### 通用检查项
- **防火墙**: firewalld和ufw应该关闭
- **SELinux**: 应该禁用或未安装
- **Swap**: 应该禁用
- **时区**: 建议设置为Asia/Shanghai
- **时间同步**: chronyd或ntp应该运行
- **kubelet**: Kubernetes节点代理
- **kubectl**: Kubernetes命令行工具
- **kubeadm**: Kubernetes集群初始化工具
- **容器运行时**: Docker或Containerd
- **数据目录**: kubelet、containerd、docker数据目录不应位于/home

### Master节点专用检查项
- **K8s组件**: kube-apiserver, kube-controller-manager, kube-scheduler
- **etcd**: 集群数据存储

### GPU Worker节点专用检查项
- **GPU**: NVIDIA驱动和工具
- **DCGM**: GPU监控和管理工具

---

**生成工具**: Kubernetes集群健康检查工具 v2.2  
**详细报告**: 请查看同目录下的HTML报告文件获取详细信息
EOF

echo "✅ 简化Markdown报告生成完成"
echo "📄 报告文件: $OUTPUT_FILE"
echo ""
echo "📋 报告摘要:"
echo "   Master节点: $(grep -c master <<< "${all_reports[*]}")"
echo "   CPU Worker节点: $(grep -c cpu_worker <<< "${all_reports[*]}")"
echo "   GPU Worker节点: $(grep -c gpu_worker <<< "${all_reports[*]}")"
echo ""
echo "💡 提示: 可以使用Markdown查看器或编辑器打开报告文件"
