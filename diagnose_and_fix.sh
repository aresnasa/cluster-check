#!/bin/bash

# ===========================================
# 诊断和修复报告生成问题的脚本
# ===========================================

echo "🔍 Kubernetes 集群健康检查工具 - 问题诊断脚本"
echo "================================================"

# 检查当前目录
echo "📂 当前工作目录: $(pwd)"
echo ""

# 检查必要文件
echo "📋 检查必要文件:"
files_to_check=(
    "unified_cluster_check_playbook_v2.yml"
    "play4_only.yml"
    "generate_unified_report.sh"
    "inventory_unified.ini"
    "Makefile"
)

for file in "${files_to_check[@]}"; do
    if [[ -f "$file" ]]; then
        echo "✅ $file - 存在"
    else
        echo "❌ $file - 不存在"
    fi
done
echo ""

# 检查目录结构
echo "📁 检查目录结构:"
directories=(
    "cluster_check_results"
    "report"
    "templates"
)

for dir in "${directories[@]}"; do
    if [[ -d "$dir" ]]; then
        echo "✅ $dir/ - 存在"
        file_count=$(find "$dir" -name "*.html" 2>/dev/null | wc -l | tr -d ' ')
        echo "   📄 HTML文件数量: $file_count"
    else
        echo "❌ $dir/ - 不存在"
        echo "   🔧 正在创建目录: $dir"
        mkdir -p "$dir"
    fi
done
echo ""

# 检查报告文件状态
echo "📊 报告文件状态分析:"
echo "--- cluster_check_results 目录 ---"
if [[ -d "cluster_check_results" ]]; then
    ls -la cluster_check_results/*.html 2>/dev/null || echo "   没有找到HTML文件"
    echo "   Master节点报告: $(ls cluster_check_results/*master*.html 2>/dev/null | wc -l | tr -d ' ') 个"
    echo "   CPU Worker报告: $(ls cluster_check_results/*cpu_worker*.html 2>/dev/null | wc -l | tr -d ' ') 个"
    echo "   GPU Worker报告: $(ls cluster_check_results/*gpu_worker*.html 2>/dev/null | wc -l | tr -d ' ') 个"
else
    echo "   cluster_check_results 目录不存在"
fi

echo ""
echo "--- report 目录 ---"
if [[ -d "report" ]]; then
    ls -la report/*.html 2>/dev/null || echo "   没有找到HTML文件"
    echo "   MASTER报告: $(ls report/MASTER_*.html 2>/dev/null | wc -l | tr -d ' ') 个"
    echo "   CPU_WORKER报告: $(ls report/CPU_WORKER_*.html 2>/dev/null | wc -l | tr -d ' ') 个"
    echo "   GPU_WORKER报告: $(ls report/GPU_WORKER_*.html 2>/dev/null | wc -l | tr -d ' ') 个"
    if [[ -f "report/unified_cluster_report.html" ]]; then
        echo "   ✅ 统一汇总报告: 已生成"
        echo "   📏 文件大小: $(ls -lh report/unified_cluster_report.html | awk '{print $5}')"
    else
        echo "   ❌ 统一汇总报告: 未生成"
    fi
else
    echo "   report 目录不存在"
fi
echo ""

# 检查 generate_unified_report.sh 权限
echo "🔧 检查脚本权限:"
if [[ -f "generate_unified_report.sh" ]]; then
    perms=$(ls -l generate_unified_report.sh | awk '{print $1}')
    echo "   generate_unified_report.sh: $perms"
    if [[ -x "generate_unified_report.sh" ]]; then
        echo "   ✅ 脚本具有执行权限"
    else
        echo "   ⚠️  脚本缺少执行权限，正在修复..."
        chmod +x generate_unified_report.sh
        echo "   ✅ 权限已修复"
    fi
else
    echo "   ❌ generate_unified_report.sh 不存在"
fi
echo ""

# 检查依赖
echo "🔍 检查系统依赖:"
commands_to_check=(
    "ansible-playbook"
    "ansible"
    "python3"
)

for cmd in "${commands_to_check[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        version_info=$($cmd --version 2>/dev/null | head -1)
        echo "   ✅ $cmd: $version_info"
    else
        echo "   ❌ $cmd: 未安装"
    fi
done
echo ""

# 提供解决方案
echo "🚀 解决方案建议:"
echo "================================================"

# 检查是否有报告数据可供汇总
if [[ $(find cluster_check_results -name "*.html" 2>/dev/null | wc -l | tr -d ' ') -gt 0 ]]; then
    echo "1. ✅ 发现已有报告数据，可以直接运行 Play 4 汇总:"
    echo "   命令: make report-only"
    echo ""
else
    echo "1. ⚠️  没有发现报告数据，需要先运行检查:"
    echo "   演示模式: make check"
    echo "   生产模式: make prod"
    echo ""
fi

echo "2. 🔧 如果 Play 4 运行失败，可以手动生成报告:"
echo "   命令: ./generate_unified_report.sh ./report"
echo ""

echo "3. 📊 查看生成的报告:"
echo "   命令: make show-reports"
echo ""

echo "4. 🧹 如果遇到问题，可以清理后重新开始:"
echo "   命令: make clean"
echo ""

# 提供快速修复选项
echo "🔧 快速修复选项:"
echo "================================================"
read -p "是否要立即运行 Play 4 汇总报告? (y/N): " run_play4
if [[ "$run_play4" =~ ^[Yy]$ ]]; then
    echo "🚀 正在运行 Play 4..."
    make report-only
elif [[ $(find cluster_check_results -name "*.html" 2>/dev/null | wc -l | tr -d ' ') -eq 0 ]]; then
    read -p "没有发现报告数据，是否要运行演示模式检查? (y/N): " run_demo
    if [[ "$run_demo" =~ ^[Yy]$ ]]; then
        echo "🚀 正在运行演示模式检查..."
        make check
    fi
fi

echo ""
echo "🎉 诊断完成！"
