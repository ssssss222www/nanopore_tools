GUPPY=/mnt/TWET-20250901A/ymm/nanoTrans/build/ont-guppy-gpu/bin/guppy_basecaller

for sample in col0_4 vir1_1 vir1_4; do
    # 判断输入路径
    if [[ $sample == col0_4 ]]; then
        input="/media/user/Elements_YMM/Nanopore/data/AT_vir/control/${sample}/fast5_multi"
    else
        input="/media/user/Elements_YMM/Nanopore/data/AT_vir/treatment/${sample}/fast5_multi"
    fi

    echo "========== 处理样本: $sample =========="
    $GUPPY \
        --flowcell FLO-MIN106 \
        --kit SQK-RNA001 \
        --recursive \
        --input_path "$input" \
        --save_path /mnt/TWET-20250901A/ymm/rebasecalled/${sample} \
        --fast5_out \  # 关键参数
        --trim_strategy none \  # 关键参数
        --u_substitution false \
        --reverse_sequence false \
        --device cuda:2 \
        --num_callers 4 \
        --gpu_runners_per_device 6
    echo "========== $sample 完成 =========="
done