#include<string>
#include<vector>

class SymbolInfo {
    std::string name, type;
    int start, end, stackOffset;
    bool isFunction = false, isArray = false, isdefined = false, isGlobal=true;
    std::vector<std::string> functionTypeList;
    SymbolInfo *next;
public:
    SymbolInfo() {
        name = "";
        type = "";
        next = NULL;
    }
    SymbolInfo(std::string name, std::string type,int start=0,int end=0) {
        this->name = name;
        this->type = type;
        this->start = start;
        this->end = end;
        next = NULL;
    }
    SymbolInfo(std::string name, std::string type,bool isFunction,bool isArray, int start=0,int end=0) {
        this->name = name;
        this->type = type;
        this->start = start;
        this->end = end;
        this->isFunction = isFunction;
        this->isArray = isArray;
        next = NULL;
    }
    SymbolInfo(std::string name, std::string type,bool isGlobal,int stackOffset) {
        this->name = name;
        this->type = type;
        this->isGlobal=isGlobal;
        this->stackOffset=stackOffset;
        next = NULL;
    }
    SymbolInfo(std::string name, std::string type,bool isGlobal,int stackOffset,bool isFunction,bool isArray) {
        this->name = name;
        this->type = type;
        this->isGlobal=isGlobal;
        this->stackOffset=stackOffset;
        this->isFunction = isFunction;
        this->isArray = isArray;
        next = NULL;
    }
    //getters
    std::string getName() {
        return name;
    }
    std::string getType() {
        return type;
    }
    SymbolInfo* getNext() {
        return next;
    }
    int getStart() {
        return start;
    }
    int getEnd() {
        return end;
    }
    bool getIsFunction() {
        return isFunction;
    }
    bool getIsArray() {
        return isArray;
    }
    bool getIsDefined() {
        return isdefined;
    }
    bool getIsGlobal() {
        return isGlobal;
    }
    int getStackOffset() {
        return stackOffset;
    }
    std::vector<std::string> getFunctionTypeList() {
        return functionTypeList;
    }
    //setter
    void setName(std::string name) {
        this->name = name;
    }
    void setType(std::string type) {
        this->type = type;
    }
    void setNext(SymbolInfo *next) {
        this->next = next;
    }
    void setStart(int start) {
        this->start = start;
    }
    void setEnd(int end) {
        this->end = end;
    }
    void setIsFunction(bool isFunction) {
        this->isFunction = isFunction;
    }
    void setIsArray(bool isArray) {
        this->isArray = isArray;
    }
    void setIsDefined(bool isdefined) {
        this->isdefined = isdefined;
    }
    void addFunctionType(std::string type) {
        functionTypeList.push_back(type);
    }

    std::string toString() {
        return "Name: " + name + " Type: " + type + " Start:" + std::to_string(start) + " End: " + std::to_string(end) + " isFunction: " + std::to_string(isFunction) + " isArray: " + std::to_string(isArray) + " isDefined: " + std::to_string(isdefined) + " isGlobal: " + std::to_string(isGlobal) + " stackOffset: " + std::to_string(stackOffset);
    }

};