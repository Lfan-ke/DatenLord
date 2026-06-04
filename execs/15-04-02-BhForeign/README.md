# 15-04-02 BH 调 C（DPI-C/BDPI，真跑通）
BH 的 `.bs` 不支持 `import "BDPI"` 串语法，且裸 `foreign` 是底层原语(内部 ABI，bluesim 不为其生成用户原型)。
真实可用法：**用一个 BSV 文件做 `import "BDPI"` 导出，BH `import` 该包调用**（BSV/BH 同编译器，可互 import）。
`make run` → `sum=7`（C 的 c_add(3,4)）。
