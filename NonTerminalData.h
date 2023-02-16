#include<string>
#include<vector>

class NonTerminalData {
public:
    std::string name,parseTreeString;
    float value=1;
    std::vector<NonTerminalData*> expandedParseTree;
    int startLineNumber,endLineNumber;
    bool isFunction;
    std::string returnType;
    std::vector<std::string> functionTypeList;
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