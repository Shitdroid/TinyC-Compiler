#include<string>
#include<vector>
#include"SymbolTable.h"

class NonTerminalData {
public:
    SymbolInfo* symbolInfo;
    std::string name,parseTreeString;
    float value=1;
    std::vector<NonTerminalData*> expandedParseTree;
    int startLineNumber,endLineNumber,offset;
    bool isFunction,isArithmetic;
    std::string returnType;
    std::vector<std::string> functionTypeList;
    std::vector<int> trueList, falseList, nextList;
    std::string getName(){
        return name;
    }
    int getStart() {
        return startLineNumber;
    }
    int getEnd() {
        return endLineNumber;
    }
    float getValue() {
        return value;
    }
};