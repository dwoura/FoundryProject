# 注意事项
传入提案时的 data，应该是带函数选择器的字节码，直接使用 abi.encode的获取的字节码是执行不了的。
可以在 remix 输入值后复制函数的 calldata。