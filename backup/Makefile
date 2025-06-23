# Kubernetes Cluster Check Tool v2.0 - Makefile
# 简化常见操作的 Makefile

.PHONY: help check demo prod clean install-deps show-reports version report-only diagnose list-tags check-master-only check-workers-only check-setup-only

# 默认目标
.DEFAULT_GOAL := help

help:
	@echo "🚀 Kubernetes 集群健康检查工具 v2.0"
	@echo ""
	@echo "📋 主要命令:"
	@echo "  make check          - 演示模式检查 (推荐，使用localhost模拟)"
	@echo "  make demo           - 同 check 命令 (演示模式)"
	@echo "  make prod           - 生产环境检查 (需要配置实际节点IP)"
	@echo "  make report-only    - 仅运行Play 4汇总报告生成 (不重新检查)"
	@echo ""
	@echo "🏷️  标签控制命令:"
	@echo "  make list-tags      - 显示所有可用的标签"
	@echo "  make check-master-only    - 仅检查Master节点"
	@echo "  make check-workers-only   - 仅检查Worker节点"
	@echo "  make check-setup-only     - 仅运行环境准备阶段"
	@echo ""
	@echo "🔧 维护命令:"
	@echo "  make show-reports   - 显示并打开报告"
	@echo "  make clean          - 清理临时文件和报告"
	@echo "  make install-deps   - 安装依赖（macOS）"
	@echo "  make version        - 显示版本信息"
	@echo "  make diagnose       - 诊断和修复报告生成问题"
	@echo ""
	@echo "📖 使用说明:"
	@echo "  - 演示模式: 使用localhost模拟不同类型节点，适合开发测试"
	@echo "  - 生产模式: 需要在inventory_unified.ini中配置实际节点IP"
	@echo "  - 报告位置: ./report/unified_cluster_report.html"
	@echo "  - 标签使用: 详见 TAGS_USAGE.md 文档"
	@echo ""

# 显示所有可用标签
list-tags:
	@echo "🏷️  查看主playbook可用标签..."
	@ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml --list-tags
	@echo ""
	@echo "🏷️  查看Play 4独立版本可用标签..."
	@ansible-playbook -i inventory_unified.ini play4_only.yml --list-tags

# 仅检查Master节点
check-master-only:
	@echo "🎯 仅运行Master节点检查（演示模式）..."
	@ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml \
		--tags "p1_master_setup,p1_master_check,p1_master_fetch,p1_master_cleanup,p4_local_setup,p4_collect_reports,p4_process_reports,p4_generate_unified,p4_finalize" \
		--limit "k8s_masters_demo:localhost" \
		-v

# 仅检查Worker节点（CPU + GPU）
check-workers-only:
	@echo "🎯 仅运行Worker节点检查（演示模式）..."
	@ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml \
		--tags "p2_cpu_worker_setup,p2_cpu_worker_check,p2_cpu_worker_fetch,p2_cpu_worker_cleanup,p3_gpu_worker_setup,p3_gpu_worker_check,p3_gpu_worker_fetch,p3_gpu_worker_cleanup,p4_local_setup,p4_collect_reports,p4_process_reports,p4_generate_unified,p4_finalize" \
		--limit "k8s_cpu_workers_demo:k8s_gpu_workers_demo:localhost" \
		-v

# 仅运行环境准备阶段
check-setup-only:
	@echo "🎯 仅运行环境准备阶段（演示模式）..."
	@ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml \
		--tags "setup" \
		--limit "k8s_masters_demo:k8s_cpu_workers_demo:k8s_gpu_workers_demo:localhost" \
		-v

# 仅运行远程清理操作
cleanup-remote-only:
	@echo "🧹 仅运行远程临时文件清理..."
	@ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml \
		--tags "cleanup" \
		--limit "k8s_masters_demo:k8s_cpu_workers_demo:k8s_gpu_workers_demo:localhost" \
		-v

# v2.0 演示模式检查 (推荐)
check:
	@echo "🚀 启动 Kubernetes 集群健康检查 v2.0 (演示模式)..."
	@echo "🔍 检查必要依赖..."
	@if ! command -v ansible-playbook >/dev/null 2>&1; then \
		echo "❌ ansible-playbook 未安装，请运行 'make install-deps'"; \
		exit 1; \
	fi
	@if [ ! -f inventory_unified.ini ]; then \
		echo "❌ inventory_unified.ini 文件不存在，请检查配置"; \
		exit 1; \
	fi
	@if [ ! -f unified_cluster_check_playbook_v2.yml ]; then \
		echo "❌ unified_cluster_check_playbook_v2.yml 文件不存在"; \
		exit 1; \
	fi
	@echo "✅ 依赖检查通过"
	@echo "📂 准备本地目录..."
	@mkdir -p ./report
	@mkdir -p ./cluster_check_results
	@echo ""
	@echo "🎯 执行v2版本演示检查 (localhost模拟)..."
	@echo "   📍 模拟 Master 节点检查 (localhost)"
	@echo "   📍 模拟 CPU Worker 节点检查 (localhost)"  
	@echo "   📍 模拟 GPU Worker 节点检查 (localhost, 含DCGM功能演示)"
	@echo "   📍 copy模板 -> 远程执行 -> 结果回传 -> 本地汇总"
	@echo ""
	@echo "ℹ️  注意: 这是v2演示模式，使用统一inventory配置的demo组"
	@echo ""
	@ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml -v --limit "k8s_masters_demo:k8s_cpu_workers_demo:k8s_gpu_workers_demo"
	@echo ""
	@echo "📊 v2版本演示检查完成!"
	@$(MAKE) show-reports

# 演示模式 (同 check 命令)
demo: check

# v2.0 生产环境检查
prod:
	@echo "🚀 启动 Kubernetes 集群健康检查 v2.0 (生产环境)..."
	@echo "⚠️  注意: 这将连接到inventory_unified.ini中配置的实际节点"
	@echo "🔍 检查必要依赖..."
	@if ! command -v ansible-playbook >/dev/null 2>&1; then \
		echo "❌ ansible-playbook 未安装，请运行 'make install-deps'"; \
		exit 1; \
	fi
	@if [ ! -f inventory_unified.ini ]; then \
		echo "❌ inventory_unified.ini 文件不存在，请检查配置"; \
		exit 1; \
	fi
	@if [ ! -f unified_cluster_check_playbook_v2.yml ]; then \
		echo "❌ unified_cluster_check_playbook_v2.yml 文件不存在"; \
		exit 1; \
	fi
	@echo "✅ 依赖检查通过"
	@echo "📂 准备本地目录..."
	@mkdir -p ./report
	@mkdir -p ./cluster_check_results
	@echo ""
	@echo "🎯 执行v2版本生产环境检查..."
	@echo "   📍 Master 节点检查"
	@echo "   📍 CPU Worker 节点检查"  
	@echo "   📍 GPU Worker 节点检查 (含DCGM功能)"
	@echo "   📍 copy模板 -> 远程执行 -> 结果回传 -> 本地汇总"
	@echo ""
	@echo "ℹ️  注意: 这是v2生产模式，使用统一inventory配置的生产组"
	@echo ""
	@read -p "是否继续连接实际节点? (y/N): " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		ansible-playbook -i inventory_unified.ini unified_cluster_check_playbook_v2.yml -v --limit "k8s_masters:k8s_cpu_workers:k8s_gpu_workers"; \
	else \
		echo "已取消操作"; \
		exit 0; \
	fi
	@echo ""
	@echo "📊 v2版本生产环境检查完成!"
	@$(MAKE) show-reports

# 显示并打开报告
show-reports:
	@echo "📊 报告汇总:"
	@if [ -d "./report" ]; then \
		echo "   🎛️  Master 节点报告: $$(ls ./report/MASTER_*.html 2>/dev/null | wc -l | tr -d ' ') 个"; \
		echo "   🖥️  CPU Worker 报告: $$(ls ./report/CPU_WORKER_*.html 2>/dev/null | wc -l | tr -d ' ') 个"; \
		echo "   🎮 GPU Worker 报告: $$(ls ./report/GPU_WORKER_*.html 2>/dev/null | wc -l | tr -d ' ') 个"; \
	fi
	@echo "📁 报告保存位置: ./report/"
	@if [ -f "./report/unified_cluster_report.html" ]; then \
		echo "🌐 打开统一汇总报告..."; \
		echo "📊 统一报告: ./report/unified_cluster_report.html"; \
		if command -v open >/dev/null 2>&1; then \
			open "./report/unified_cluster_report.html"; \
		elif command -v xdg-open >/dev/null 2>&1; then \
			xdg-open "./report/unified_cluster_report.html"; \
		else \
			echo "请手动打开: ./report/unified_cluster_report.html"; \
		fi; \
	else \
		echo "⚠️  统一汇总报告不存在，请先运行检查"; \
	fi

# 显示版本信息
version:
	@if [ -f VERSION ]; then \
		echo "🏷️  版本信息:"; \
		cat VERSION; \
	else \
		echo "VERSION 文件不存在"; \
	fi

# 清理临时文件和报告
clean:
	@echo "🧹 清理临时文件和报告..."
	@rm -rf ./report/*.html 2>/dev/null || true
	@rm -rf ./cluster_check_results/*.html 2>/dev/null || true
	@rm -rf /tmp/cluster_check_results/* 2>/dev/null || true
	@rm -f /tmp/cluster_check.sh 2>/dev/null || true
	@rm -f /tmp/cluster_check.sh.j2 2>/dev/null || true
	@echo "✅ 清理完成"

# 安装依赖 (macOS)
install-deps:
	@echo "📦 安装 macOS 依赖..."
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "❌ Homebrew 未安装，请先安装 Homebrew: https://brew.sh/"; \
		exit 1; \
	fi
	@echo "安装 Ansible..."
	@brew install ansible
	@echo "✅ 依赖安装完成"
	@echo "🔧 验证安装..."
	@ansible --version
	@ansible-playbook --version

# 仅运行Play 4汇总报告生成
report-only:
	@echo "📋 仅运行Play 4 - 本地汇总集群检查报告..."
	@echo "🔍 检查必要依赖..."
	@if ! command -v ansible-playbook >/dev/null 2>&1; then \
		echo "❌ ansible-playbook 未安装，请运行 'make install-deps'"; \
		exit 1; \
	fi
	@if [ ! -f inventory_unified.ini ]; then \
		echo "❌ inventory_unified.ini 文件不存在，请检查配置"; \
		exit 1; \
	fi
	@if [ ! -f play4_only.yml ]; then \
		echo "❌ play4_only.yml 文件不存在"; \
		exit 1; \
	fi
	@echo "✅ 依赖检查通过"
	@echo "📂 准备本地目录..."
	@mkdir -p ./report
	@mkdir -p ./cluster_check_results
	@echo ""
	@echo "🎯 仅执行 Play 4 - 本地汇总报告生成..."
	@echo "   📊 检查已有报告文件"
	@echo "   📁 复制和重命名报告文件"
	@echo "   📋 生成统一汇总报告"
	@echo ""
	@ansible-playbook -i inventory_unified.ini play4_only.yml -v
	@echo ""
	@echo "📊 Play 4 报告汇总完成!"
	@$(MAKE) show-reports

# 诊断和修复报告生成问题
diagnose:
	@echo "🔍 启动问题诊断工具..."
	@if [ ! -f diagnose_and_fix.sh ]; then \
		echo "❌ diagnose_and_fix.sh 文件不存在"; \
		exit 1; \
	fi
	@if [ ! -x diagnose_and_fix.sh ]; then \
		echo "🔧 添加执行权限..."; \
		chmod +x diagnose_and_fix.sh; \
	fi
	@./diagnose_and_fix.sh

