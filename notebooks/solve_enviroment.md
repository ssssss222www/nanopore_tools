# NanoTrans 的环境配置
conda 环境解析卡住是安装过程中常见的问题，用 mamba 替代 conda 能够快速解决这个问题。

## 先安装 mamba
```bash
cd /mnt/TWET-20250901A/YMM/NanoTrans
$build_dir/miniconda3/bin/conda install -n base -c conda-forge mamba -y
```
## 如果安装mamba过程中仍然卡住，尝试直接下载mamba二进制文件
```bash
cd /mnt/TWET-20250901A/YMM/NanoTrans/build/miniconda3/bin
wget https://micro.mamba.pm/api/micromamba/linux-64/latest -O micromamba.tar.bz2
tar -xjf micromamba.tar.bz2
ls -la

if [ -f bin/micromamba ]; then
    mv bin/micromamba ./
    rmdir bin
fi

chmod +x micromamba

./micromamba --version

rm micromamba.tar.bz2
```

## 使用mamba创建nanopolish的环境， 并安装nanopolish
```bash
./miniconda3/bin/micromamba create -y -p $(pwd)/nanopolish_conda_env python=3.9 -c conda-forge

ls -la | grep nanopolish

cd /mnt/TWET-20250901A/YMM/NanoTrans/build
./miniconda3/bin/micromamba install -y -p ./nanopolish_conda_env nanopolish=0.14.0 -c conda-forge -c bioconda

touch ./nanopolish_conda_env/bin/installed  # 安装完成后标记
```

# 服务器Ⅳ使用micromamba创建环境（DiskF）
## 下载micromamba
```bash
cd /mnt/TenTC-0eec  # 切换到DiskF

conda deactivate  # 退出base环境

curl -L https://micro.mamba.pm/api/micromamba/linux-64/latest | tar -xvj bin/micromamba

mkdir -p software
mv bin/micromamba software/
/mnt/TenTC-0eec/software/micromamba --version
```

## 加入 PATH
```bash
nano ~/.bashrc

export PATH=/mnt/TenTC-0eec/software:$PATH

source ~/.bashrc

micromamba --version
```

## 设置micromamba 所有数据都放 DiskF
```bash
mkdir -p /mnt/TenTC-oeec/micromamba  ## 暂停在这一步

nano ~/.bashrc

export MAMBA_ROOT_PREFIX=/mnt/TenTC-0eec/micromamba

source ~/.bashrc

micromamba shell init -s bash

source ~/.bashrc

micromamba env list
```

## 创建 micromamba 专属 config
```bash
nano /mnt/TenTC-0eec/micromamba/.condarc

channels:
  - https://mirrors.ustc.edu.cn/anaconda/cloud/conda-forge/
  - https://mirrors.ustc.edu.cn/anaconda/cloud/bioconda/
  - https://mirrors.ustc.edu.cn/anaconda/pkgs/main/

channel_priority: strict
ssl_verify: false
solver: libmamba
```

## 创建环境
```bash
conda deactivate  # 退出conda

micromamba create -p /mnt/TenTC-0eec/micromamba/envs/tailfindr -c conda-forge -c bioconda r-base

micromamba activate tailfindr
```
