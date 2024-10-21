# 裁判软件使用

> 官方需要用到的裁判软件有[ssl-game-controller](https://github.com/RoboCup-SSL/ssl-game-controller)和[ssl-autoref](https://github.com/TIGERs-Mannheim/AutoReferee)
> 除此以外，还有一个比赛常用的[ssl-status-board](https://github.com/RoboCup-SSL/ssl-status-board)用于裁判信息的可视化

> 目前比赛中，主要在使用[TIGERs-Mannheim](https://github.com/TIGERs-Mannheim)的自动裁判盒，所以以下内容`ssl-autoref`如无特殊说明，均指`TIGERs-Mannheim`的自动裁判盒。

三个软件与`ssl-vision`共同构成了RoboCup-SSL比赛的基础设施，四个软件的通信大致如下：

```{thumbnail} ../../img/p1_3_ssl_all.png
```

## **ssl-game-controller**

`ssl-game-controller`是RoboCup-SSL官方提供的裁判软件，用于控制比赛的进行，包括比赛时间、比分、暂停、继续、罚牌等功能。

```{thumbnail} ../../img/p1_3_ssl_game_controller.png
```

### **Option 1**. 下载编译好的二进制文件

game-controller软件使用golang进行编写，官方已经为每个[Release版本](https://github.com/RoboCup-SSL/ssl-game-controller/releases)提供了编译好的二进制文件，可以直接下载使用。

:::{admonition} 提示
下载的文件如果需要在Ubuntu下运行，需要手动添加可执行权限（`chmod +x ssl-game-controller`）
:::

### **Option 2**. ssl-gc从源码编译(Ubuntu 22.04)

* 安装golang环境
    ```bash
    sudo snap install go --classic
    # 可选：配置proxy
    go env -w GO111MODULE=on
    go env -w GOPROXY=https://goproxy.cn,direct
    ```
* 安装nodejs环境，[参考官网](https://nodejs.org/en/download/package-manager)(具体版本以官网最新为准)

    ```bash
    # installs nvm (Node Version Manager)
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

    # download and install Node.js (you may need to restart the terminal)
    nvm install 20

    # verifies the right Node.js version is in the environment
    node -v

    # verifies the right npm version is in the environment
    npm -v #
    ```
* 编译
    ```bash
    git clone https://github.com/RoboCup-SSL/ssl-game-controller
    cd ssl-game-controller
    make install
    ```
* 执行
    编译完成后，你可以在golang的bin文件夹(默认目录为`$HOME/go/bin`)下找到`ssl-game-controller`二进制文件，运行即可。

### ssl-gc使用（TODO）

## **ssl-status-board**

`ssl-status-board`是RoboCup-SSL官方提供的裁判信息可视化软件，用于显示比赛的信息，包括比分、比赛时间、罚牌等。

```{thumbnail} ../../img/p1_3_ssl_status_board.png
```

### **Option 1**. 下载编译好的二进制文件

官方已经为每个[Release版本](https://github.com/RoboCup-SSL/ssl-status-board/releases)提供了编译好的二进制文件，可以直接下载使用。

### **Option 2**. 从源码编译

ssl-status-board的编译环境与ssl-game-controller相同，可以参考上文的编译方法。

```bash
git clone https://github.com/RoboCup-SSL/ssl-status-board
cd ssl-status-board
make install
```
编译后的二进制文件在golang的bin文件夹(默认目录为`$HOME/go/bin`)下，运行即可。

### ssl-sb使用（TODO）

## **ssl-autoref**

`ssl-autoref`是TIGERs-Mannheim提供的自动裁判盒软件，用于自动裁判比赛，包括判断球门是否进球、判断球是否出界、判断球员是否犯规等。

```{thumbnail} ../../img/p1_3_ssl_autoref.png
```

### **Option 1**. 下载编译好的二进制文件

官方已经为每个[Release版本](https://github.com/TIGERs-Mannheim/AutoReferee/releases)提供了编译好的二进制文件，可以直接下载使用。

下载好的文件是一个压缩包，解压后进入到`autoReferee`文件夹，运行`./bin/autoReferee`即可。

### **Option 2**. 从源码编译

* 安装openjdk环境
    ```bash
    sudo apt install openjdk-11-jdk
    ```
* 编译
    ```bash
    git clone https://github.com/TIGERs-Mannheim/AutoReferee
    cd AutoReferee
    ./build.sh
    ```
* 执行
    ```bash
    ./run.sh
    ```

### ssl-autoref使用（TODO）