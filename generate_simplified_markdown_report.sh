#!/bin/bash

# ===========================================
# 简化版Markdown报告生成脚本
# 功能：从HTML报告提取关键检查项的通过/失败状态，生成简洁的Markdown汇总报告
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

# 检查是否有报告文件（HTML或TXT）
html_files_count=$(find "$SOURCE_DIR" -name "*.html" -type f | wc -l)
txt_files_count=$(find "$SOURCE_DIR" -name "*.txt" -type f | wc -l)
total_files_count=$((html_files_count + txt_files_count))

if [[ $total_files_count -eq 0 ]]; then
    echo "❌ 错误: 在 $SOURCE_DIR 目录下没有找到报告文件（HTML或TXT）"
    echo "请先运行集群检查生成各节点的检查报告"
    exit 1
fi

echo "📁 源目录: $SOURCE_DIR"
echo "📁 输出目录: $REPORT_DIR" 
echo "📄 找到 $html_files_count 个HTML报告文件，$txt_files_count 个TXT报告文件"

# 提取主要检查项状态的函数
extract_status() {
    local report_file="$1"
    local check_type="$2"
    
    if [[ ! -f "$report_file" ]]; then
        echo "❓"
        return
    fi
    
    # 判断文件类型
    local file_ext="${report_file##*.}"
    
    case "$check_type" in
        "system")
            # 系统检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查 - 优先检查问题状态
                if grep -q "❌.*系统配置检查\|❌.*防火墙\|❌.*SELinux\|❌.*Swap\|❌.*时区\|❌.*CPU调频策略.*powersave\|❌.*CPU调频.*powersave" "$report_file" 2>/dev/null; then
                    echo "❌"
                elif grep -q "⚠️.*系统配置检查\|⚠️.*防火墙\|⚠️.*SELinux\|⚠️.*Swap\|⚠️.*时区\|⚠️.*CPU调频策略\|⚠️.*CPU调频" "$report_file" 2>/dev/null; then
                    echo "⚠️"
                elif grep -q "✅.*系统配置检查\|✅.*防火墙\|✅.*SELinux\|✅.*Swap\|✅.*时区\|✅.*CPU调频策略.*performance\|✅.*CPU调频.*performance" "$report_file" 2>/dev/null; then
                    echo "✅"
                else
                    echo "❓"
                fi
            else
                # HTML文件格式检查 - 优先检查问题状态
                if grep -q "系统检查:.*error.*失败\|系统检查:.*<span.*error.*失败\|CPU调频策略.*error.*powersave\|CPU调频.*error.*powersave" "$report_file" 2>/dev/null; then
                    echo "❌"
                elif grep -q "系统检查:.*warning.*警告\|系统检查:.*<span.*warning.*警告\|CPU调频策略.*warning\|CPU调频.*warning" "$report_file" 2>/dev/null || \
                     (grep -q "CPU调频策略" "$report_file" && grep -q "status warning" "$report_file") 2>/dev/null; then
                    echo "⚠️"
                elif grep -q "系统检查:.*success.*成功\|系统检查:.*<span.*success.*成功\|CPU调频策略.*success.*performance\|CPU调频.*success.*performance" "$report_file" 2>/dev/null || \
                     (grep -q "CPU调频策略" "$report_file" && grep -q "status success" "$report_file") 2>/dev/null; then
                    echo "✅"
                else
                    echo "❓"
                fi
            fi
            ;;
        "kubernetes")
            # Kubernetes检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查
                if grep -q "✅.*kubelet\|✅.*kubeadm\|✅.*kubectl" "$report_file" 2>/dev/null; then
                    echo "✅"
                elif grep -q "❌.*kubelet\|❌.*kubeadm" "$report_file" 2>/dev/null; then
                    echo "❌"
                elif grep -q "⚠️.*kubectl" "$report_file" 2>/dev/null; then
                    echo "⚠️"
                else
                    echo "❓"
                fi
            else
                # HTML文件格式检查
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
            fi
            ;;
        "gpu")
            # GPU/DCGM检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查
                if grep -q "✅.*NVIDIA SMI\|✅.*DCGM" "$report_file" 2>/dev/null; then
                    echo "✅"
                elif grep -q "❌.*NVIDIA SMI\|❌.*DCGM" "$report_file" 2>/dev/null; then
                    echo "❌"
                elif grep -q "⚠️.*DCGM" "$report_file" 2>/dev/null; then
                    echo "⚠️"
                elif ! grep -q "NVIDIA SMI\|DCGM" "$report_file" 2>/dev/null; then
                    echo "N/A"
                else
                    echo "❓"
                fi
            else
                # HTML文件格式检查
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
            fi
            ;;
        "ib")
            # InfiniBand检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查
                if grep -q "✅.*ibstat工具.*已安装\|✅.*IB端口状态.*Active" "$report_file" 2>/dev/null; then
                    echo "✅"
                elif grep -q "❌.*ibstat工具\|❌.*IB端口状态" "$report_file" 2>/dev/null; then
                    echo "❌"
                elif grep -q "⚠️.*ibstat工具\|⚠️.*IB端口状态" "$report_file" 2>/dev/null; then
                    echo "⚠️"
                elif ! grep -q "ibstat\|InfiniBand\|IB端口" "$report_file" 2>/dev/null; then
                    echo "N/A"
                else
                    echo "❓"
                fi
            else
                # HTML文件格式检查
                if grep -q "InfiniBand.*检查:.*success.*成功\|InfiniBand.*检查:.*<span.*success.*成功\|IB.*检查:.*success.*成功\|IB.*检查:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                    echo "✅"
                elif grep -q "InfiniBand.*检查:.*error.*失败\|InfiniBand.*检查:.*<span.*error.*失败\|IB.*检查:.*error.*失败\|IB.*检查:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                    echo "❌"
                elif grep -q "InfiniBand.*检查:.*warning.*警告\|InfiniBand.*检查:.*<span.*warning.*警告\|IB.*检查:.*warning.*警告\|IB.*检查:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                    echo "⚠️"
                elif ! grep -q "InfiniBand.*检查\|IB.*检查" "$report_file" 2>/dev/null; then
                    echo "N/A"
                else
                    echo "❓"
                fi
            fi
            ;;
        "resource")
            # 资源检查状态
            if [[ "$file_ext" == "txt" ]]; then
                # TXT文件格式检查 - 基于目录检查结果
                if grep -q "✅.*数据目录\|✅.*kubelet数据目录\|✅.*containerd数据目录\|✅.*docker数据目录" "$report_file" 2>/dev/null; then
                    echo "✅"
                elif grep -q "⚠️.*数据目录\|⚠️.*kubelet数据目录\|⚠️.*containerd数据目录\|⚠️.*docker数据目录" "$report_file" 2>/dev/null; then
                    echo "⚠️"
                elif grep -q "❌.*数据目录\|❌.*kubelet数据目录\|❌.*containerd数据目录\|❌.*docker数据目录" "$report_file" 2>/dev/null; then
                    echo "❌"
                else
                    echo "❓"
                fi
            else
                # HTML文件格式检查
                if grep -q "资源状态:.*success.*成功\|资源状态:.*<span.*success.*成功" "$report_file" 2>/dev/null; then
                    echo "✅"
                elif grep -q "资源状态:.*warning.*警告\|资源状态:.*<span.*warning.*警告" "$report_file" 2>/dev/null; then
                    echo "⚠️"
                elif grep -q "资源状态:.*error.*失败\|资源状态:.*<span.*error.*失败" "$report_file" 2>/dev/null; then
                    echo "❌"
                else
                    echo "❓"
                fi
            fi
            ;;
        *)
            echo "❓"
            ;;
    esac
}

# 获取节点类型
get_node_type() {
    local hostname="$1"
    
    # 基于主机名模式判断节点类型
    if [[ "$hostname" =~ master|control ]]; then
        echo "Master"
    elif [[ "$hostname" =~ gpu ]]; then
        echo "GPU Worker"
    else
        echo "CPU Worker"
    fi
}

# 开始生成Markdown报告
echo "🔄 生成简化Markdown报告..."

cat > "$OUTPUT_FILE" << EOF
# Kubernetes集群健康检查报告 (简化版)

**生成时间**: $TIMESTAMP  
**报告类型**: 汇总展示所有节点检查结果状态

---

## 📊 集群检查结果汇总

| 主机名 | 节点类型 | 系统检查 | Kubernetes | GPU/DCGM | InfiniBand | 资源状态 | 整体状态 |
|--------|----------|----------|------------|-----------|------------|----------|----------|
EOF

# 统计信息
total_nodes=0
healthy_nodes=0
warning_nodes=0
failed_nodes=0

# 使用临时文件存储已处理的主机名，避免重复统计
processed_hosts_file="/tmp/processed_hosts_$$"
touch "$processed_hosts_file"

# 遍历所有报告文件（HTML和TXT）
for report_file in "$SOURCE_DIR"/*.html "$SOURCE_DIR"/*.txt; do
    # 检查文件是否存在（避免通配符无匹配时的问题）
    if [[ -f "$report_file" ]]; then
        # 提取主机名 - 从文件名中提取，保持完整格式
        hostname=$(basename "$report_file")
        # 移除文件扩展名
        hostname="${hostname%.*}"
        
        # 清理主机名（移除前缀，保留完整的hostname格式）
        if [[ "$hostname" =~ _check_report_ ]]; then
            hostname=$(echo "$hostname" | sed 's/.*_check_report_//')
        elif [[ "$hostname" =~ _check_simplified_ ]]; then
            hostname=$(echo "$hostname" | sed 's/.*_check_simplified_//' | sed 's/_[0-9]*$//')
        elif [[ "$hostname" =~ _check_ ]]; then
            hostname=$(echo "$hostname" | sed 's/.*_check_//' | sed 's/_[0-9]*$//')
        fi
        
        # 跳过可能的统一报告文件
        if [[ "$hostname" == "unified_cluster_report" || "$hostname" == "cluster_report" ]]; then
            continue
        fi
        
        # 进一步清理主机名：移除时间戳
        hostname=$(echo "$hostname" | sed 's/_[0-9]\{8\}_[0-9]\{6\}$//')
        
        # 如果hostname还是像20250623这样的数字，尝试从文件内容中提取
        if [[ "$hostname" =~ ^[0-9]+$ ]]; then
            # 尝试从文件内容中提取真实主机名
            local_hostname=""
            if [[ "$report_file" =~ \.html$ ]]; then
                # 从HTML文件的title标签或内容中提取主机名
                local_hostname=$(grep -o '<title>.*</title>' "$report_file" 2>/dev/null | sed 's/<title>.*- \([^<]*\)<\/title>/\1/' | tr -d ' ')
                if [[ -z "$local_hostname" || "$local_hostname" =~ ^[0-9]+$ ]]; then
                    local_hostname=$(grep -o "主机名:.*<" "$report_file" 2>/dev/null | sed 's/主机名: *\([^<]*\)<.*/\1/' | tr -d ' ')
                fi
            else
                # 从TXT文件中提取主机名
                local_hostname=$(grep "主机名:" "$report_file" 2>/dev/null | head -1 | sed 's/.*主机名: *\([^ ]*\).*/\1/')
            fi
            
            if [[ -n "$local_hostname" && ! "$local_hostname" =~ ^[0-9]+$ ]]; then
                hostname="$local_hostname"
            else
                # 如果还是无法提取，使用文件名基础部分
                base_name=$(basename "$report_file")
                if [[ "$base_name" =~ localhost ]]; then
                    hostname="localhost"
                elif [[ "$base_name" =~ test.*worker ]]; then
                    hostname=$(echo "$base_name" | grep -o 'test-[^_]*-[^_]*' | head -1)
                elif [[ "$base_name" =~ test.*master ]]; then
                    hostname=$(echo "$base_name" | grep -o 'test-[^_]*-[^_]*' | head -1)
                fi
            fi
        fi
        
        # 检查是否已处理过这个主机
        if grep -q "^$hostname$" "$processed_hosts_file" 2>/dev/null; then
            continue
        fi
        
        # 记录该主机已处理
        echo "$hostname" >> "$processed_hosts_file"
        
        total_nodes=$((total_nodes + 1))
        
        # 获取节点类型
        node_type=$(get_node_type "$hostname")
        
        # 提取各项检查状态
        system_status=$(extract_status "$report_file" "system")
        k8s_status=$(extract_status "$report_file" "kubernetes")
        gpu_status=$(extract_status "$report_file" "gpu")
        
        # IB状态检查只针对GPU Worker节点
        if [[ "$node_type" == "GPU Worker" ]]; then
            ib_status=$(extract_status "$report_file" "ib")
        else
            ib_status="➖"
        fi
        
        resource_status=$(extract_status "$report_file" "resource")
        
        # 计算整体状态
        overall_status="✅"
        if [[ "$system_status" == "❌" || "$k8s_status" == "❌" || "$gpu_status" == "❌" || "$ib_status" == "❌" || "$resource_status" == "❌" ]]; then
            overall_status="❌"
            failed_nodes=$((failed_nodes + 1))
        elif [[ "$system_status" == "⚠️" || "$k8s_status" == "⚠️" || "$gpu_status" == "⚠️" || "$ib_status" == "⚠️" || "$resource_status" == "⚠️" ]]; then
            overall_status="⚠️"
            warning_nodes=$((warning_nodes + 1))
        else
            healthy_nodes=$((healthy_nodes + 1))
        fi
        
        # 生成表格行
        echo "| **$hostname** | $node_type | $system_status | $k8s_status | $gpu_status | $ib_status | $resource_status | $overall_status |" >> "$OUTPUT_FILE"
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

# 添加图例说明
cat >> "$OUTPUT_FILE" << 'EOF'

---

## 📖 状态图例

- ✅ **通过**: 检查项配置正确，状态良好
- ❌ **失败**: 检查项存在问题，需要修复
- ⚠️ **警告**: 检查项可能存在潜在问题
- ❓ **未知**: 无法获取检查状态
- **N/A**: 不适用（如CPU节点无GPU检查）

## 🔍 检查项说明

### 主要检查项
- **系统检查**: 防火墙、SELinux、Swap、时区、时间同步等基础系统配置
- **Kubernetes**: kubelet、kubectl、kubeadm、容器运行时等K8s组件状态
- **GPU/DCGM**: GPU驱动、DCGM监控工具状态（仅GPU节点）
- **InfiniBand**: IB网络适配器状态、ibstat检查（仅配置了IB的节点）
- **资源状态**: 磁盘空间、内存使用、数据目录位置等资源检查

### 节点类型
- **Master**: Kubernetes控制平面节点
- **CPU Worker**: CPU工作节点
- **GPU Worker**: GPU工作节点

---

**生成工具**: Kubernetes集群健康检查工具 v2.2  
**详细报告**: 请查看同目录下的HTML报告文件获取详细信息
EOF

echo "✅ 简化Markdown报告生成完成"
echo "📄 报告文件: $OUTPUT_FILE"
echo ""
echo "📋 报告摘要:"
echo "   总节点数: $total_nodes"
echo "   健康节点: $healthy_nodes"
echo "   警告节点: $warning_nodes"
echo "   异常节点: $failed_nodes"
if [[ $total_nodes -gt 0 ]]; then
    health_rate=$(( (healthy_nodes * 100) / total_nodes ))
    echo "   集群健康率: ${health_rate}%"
fi
echo ""
echo "💡 提示: 可以使用Markdown查看器或编辑器打开报告文件"

# 如果健康率低于80%，输出警告
if [[ $total_nodes -gt 0 ]]; then
    health_rate=$(( (healthy_nodes * 100) / total_nodes ))
    if [[ $health_rate -lt 80 ]]; then
        echo "⚠️  警告: 集群健康率较低 (${health_rate}%)，请检查异常节点"
    fi
fi

# 清理临时文件
rm -f "$processed_hosts_file"
