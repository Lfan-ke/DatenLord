# SystemC Counter Demo

一个完整的 SystemC 计数器示例，展示现代 C++ 风格的硬件建模。

## 版本信息

| 组件 | 版本 |
|------|------|
| Ubuntu | 24.04.2 LTS |
| GCC/G++ | 13.3.0 |
| SystemC | 2.3.4 |
| C++ | 17 |

## 构建和运行

```bash
make build    # 编译示例
make run      # 编译并运行仿真
make show     # 用 GTKWave 查看波形
make clean    # 清理构建产物
```

## 功能说明

- **Counter 模块**：8 位递增计数器，支持异步复位和可配置最大值（默认 255）
- **Tester 模块**：自动化测试激励，驱动计数器并验证特定计数值和溢出
- **波形导出**：生成 VCD 文件到 `output/wave/waveform.vcd`，可用 GTKWave 查看

## 输出示例

仿真自动验证：
- count = 10 @ 125ns
- count = 50 @ 525ns
- 溢出（255→0）@ 2585ns
