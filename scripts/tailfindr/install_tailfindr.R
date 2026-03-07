# 强制装入 conda 环境的 R 库路径
.libPaths("/mnt/TenTC-0eec/micromamba/envs/tail/lib/R/library")

# 检查 rbokeh（已通过 conda 安装，应该直接跳过）
if (!requireNamespace("rbokeh", quietly = TRUE)) {
  stop("rbokeh not found! Please run: micromamba install -c conda-forge r-rbokeh")
} else {
  message("rbokeh already installed.")
}

# Install tailfindr
message("Installing tailfindr from local repository...")
devtools::install_local("/mnt/TWET-20250901A/ymm/tailfindr", dependencies = TRUE, force = TRUE)