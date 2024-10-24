## EIP712

+ hashStruct(message)
message 中有多个结构体嵌套，typeHash 应该怎么获取？写法如何？
假设有如下类型，Mail 中包含多个结构体
```
struct Attachment {
    string fileName;
    bytes fileHash;
}

struct Person {
    string name;
    address wallet;
}

struct Mail {
    Person from;
    Person to;
    string content;
    Attachment attachment;
}
```
```
bytes32 mailTypeHash = keccak256("Mail(Person from,Person to,string content,Attachment attachment)Person(string name,address wallet)Attachment(string fileName,bytes fileHash)");
```
可以看出，Mail 中的从上至下的顺序的结构体，依次按层级从左往右排列。  
格式要完整，不能多一个空格或少一个空格，例如 Mail 后面紧跟着 Person，**中间没有空格**。