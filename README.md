# 40系和50系消费级N卡之间的亲~密~联欢灵丹妙药
AI辅助成文，图个乐

> *"老黄说：消费级显卡不配拥有P2P。我们说：那是你不懂我们的爱。"*

## 🎭 故事背景

曾几何时，NVIDIA家的消费级显卡（RTX 4090、5090等）和数据中心显卡之间隔着一道鸿沟——**P2P（点对点通信）**。数据中心显卡可以手拉手、心连心，直接交换数据；而消费级显卡只能孤独地通过CPU中转，像个没人疼的孩子。

老黄（NVIDIA CEO）说："消费级显卡？那不是用来打游戏的吗？要什么P2P！"

但是！**爱情是不能被阻挡的！**

## 💊 这是什么灵丹妙药？

本项目是一套自动构建的NVIDIA内核模块，通过一些"小手段"让消费级显卡也能享受P2P的甜蜜：

- **BAR1 P2P模式**：强制启用消费级GPU的隐藏技能
- **DMA直传**：GPU之间直接交换数据，不再经过CPU这个"电灯泡"
- **自动化构建**：GitHub Actions自动同步最新驱动，省去手动编译的痛苦

## 🏗️ 工作原理（技术细节）

```
┌─────────────────────────────────────────────────────────────┐
│                    P2P 原理图解                              │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   改造前（消费级显卡的悲惨生活）:                              │
│                                                             │
│   ┌─────┐     ┌─────┐     ┌─────┐                          │
│   │GPU 1│ ←── │ CPU │ ──→ │GPU 2│   CPU: "我来当中间商~"    │
│   └─────┘     └─────┘     └─────┘                          │
│                                                             │
│   改造后（消费级显卡的甜蜜生活）:                              │
│                                                             │
│   ┌─────┐                   ┌─────┐                         │
│   │GPU 1│ ═════════════════ │GPU 2│  直接牵手！              │
│   └─────┘     BAR1 P2P      └─────┘                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```



## 🚀 快速开始

### 方式一：下载Release（推荐懒人）

1. 去 [Releases](../../releases) 页面下载最新的安装包
2. 解压并运行：
   ```bash
   tar -xzf nvidia-p2p-modules-*.tar.gz
   cd nvidia-p2p-modules-*/
   sudo ./install.sh
   ```
3. 重启并验证：
   ```bash
   sudo reboot
   # 重启后
   nvidia-smi topo -m  # 应该看到PIX或NVLink而不是SOC
   ```

### 方式二：自己编译（硬核玩家）

```bash
# 克隆仓库
git clone https://github.com/your-repo/RTX-5090-p2p-driver-latest.git
cd RTX-5090-p2p-driver-latest

# 手动编译（需要安装kernel headers和build-essential）
# 详见 GitHub Actions 工作流
```

## ⚠️ 注意事项

1. **IOMMU必须配置为直通模式**
   - 编辑 `/etc/default/grub`
   - 添加 `amd_iommu=on iommu=pt` 到 `GRUB_CMDLINE_LINUX_DEFAULT`
   - 运行 `sudo update-grub`

2. **安全警告**
   - 这个补丁禁用了IOMMU虚拟化保护
   - 不要在不信任的环境中使用
   - 后果自负，老黄不背锅

3. **内核版本**
   - 安装脚本会自动检测并安装所需内核
   - 如果内核不匹配，会提示重启后继续

## 🤖 自动化构建

本项目使用GitHub Actions自动构建，支持：

| 参数 | 默认值 | 说明 |
|------|--------|------|
| NVIDIA版本 | 最新（从GitHub API获取） | 如 595.45.04 |
| Ubuntu版本 | 最新（如25.10） | 可选LTS |
| 内核版本 | 最新（如6.17.0-19-generic） | 自动检测 |

触发方式：
- 每周日自动构建
- 手动触发（workflow_dispatch）
- Push到main/master分支

## 📦 安装脚本功能

一键安装脚本 `install.sh` 会自动：

1. ✅ 检测当前内核与所需内核
2. ✅ 自动安装匹配的内核（如需要）
3. ✅ 下载NVIDIA驱动（如未包含）
4. ✅ 安装不含GPU内核的驱动
5. ✅ 安装P2P修补过的GPU内核模块
6. ✅ 配置IOMMU和系统参数
7. ✅ 提示重启并验证

## 🙏 致谢与引用

本项目站在巨人的肩膀上：

- **[NVIDIA/open-gpu-kernel-modules](https://github.com/NVIDIA/open-gpu-kernel-modules)** - NVIDIA官方开源GPU内核模块
- **[tinygrad/open-gpu-kernel-modules](https://github.com/tinygrad/open-gpu-kernel-modules)** - 最初发现P2P补丁方法的项目
- **[ec-jt/open-gpu-kernel-modules](https://github.com/ec-jt/open-gpu-kernel-modules)** - P2P补丁的原始来源

## 📜 许可证

- NVIDIA内核模块源码：NVIDIA Software License（见 [COPYING](./COPYING)）
- 本项目的构建脚本和补丁：MIT License

---

> *"让消费级显卡也能享受P2P的快乐，这是我们对开源社区的贡献。"*
> 
> *—— 来自一群不甘寂寞的GPU爱好者*

**⚠️ 免责声明**：本项目仅供学习和研究目的。使用本补丁可能导致系统不稳定、安全风险或违反NVIDIA的许可协议。请自行承担所有风险。作者不对任何损失负责。

---

**Star ⭐ 本项目，让更多消费级显卡找到真爱！**
