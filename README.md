# MIT_CLASS_lab

## 文件说明
- class_source_code文件夹：收集的课程提供的程序
- bsv_prj文件夹：课程学习过程中，完成的或开发中的代码

## 开发环境
感谢作者kazutoiris提供的
[connectal-docker](https://github.com/kazutoiris/connectal-docker)

### 我的Docker Composer example
```
services:
  connectal:
    image: kazutoiris/connectal:latest
    volumes:
      - ".:/root"
    network_mode: none
    tty: true
    stdin_open: true
```
如果在WSL上运行docker，可能无法正常启动container。
所以需要添加以下的两行代码：
```
    tty: true
    stdin_open: true
```


## BSV语法记录
- 