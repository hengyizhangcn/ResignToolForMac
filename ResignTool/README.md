#  此文件记录该项目碰到的问题

## 1.xcrun: error: cannot be used within an App Sandbox.
意思是，不能在应用的沙盒中调用xcrun命令
参考：https://forums.developer.apple.com/thread/73554
解决：关闭沙盒即可！
## 2.SecStaticCode: verification failed (trust result 6, error -2147409652)



# 

### 1.SwiftUI三种使用状态的方式？
@State, @ObservedObject和@EnvironmentObject
参考链接：https://www.hackingwithswift.com/quick-start/swiftui/whats-the-difference-between-observedobject-state-and-environmentobject
### 2.swift中struct和class的区别
property初始化不同：struct有默认构造函数，class没有
对象变量赋值不同：struct深拷贝，class浅拷贝
immutable变量：struct遵循，一旦对象被定义为let，则不可修改，class则不同
function 改变 property 的值:struct的function要加上 mutating，而 class 不用
struct不可继承，class可以
struct对象分配在栈中，class对象在堆中
参考链接：
https://www.cnblogs.com/beckwang0912/p/8508299.html
https://stackoverflow.com/questions/24232799/why-choose-struct-over-class
