#include<string>
#include<vector>

class SymbolInfo {
    std::string name, type;
    int start, end;
    bool isFunction = false, isArray = false, isdefined = false;
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

};