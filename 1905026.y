/* %code requires{
    #include <bits/stdc++.h>
} */
%{
#include <bits/stdc++.h>
#include "NonTerminalData.h"
// #define YYSTYPE SymbolInfo*

using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;
int lineCount=1;
int errorCount=0;
int parameterOffset=4, stackOffset=-2,tempLineCount=0;
string type,functionName;
vector<string> typeList;
vector<NonTerminalData*> returnVariableList;

ofstream logOutput;
ofstream errorOutput;
ofstream parseOutput;
ofstream codeOutput;
ofstream optimizedCodeOutput;
ofstream tempCode;
bool inFunctionScope=false, enterScopeFlag=true;
int exitScopeFlag=0;

SymbolTable *table=new SymbolTable(11);


void yyerror(string s)
{
	//write your code
    logOutput<<"Error at line "<<lineCount<<": "<<s<<"\n"<<endl;
	errorOutput<<"Error at line "<<lineCount<<": "<<s<<"\n"<<endl;
    errorCount++;
}

/************************Functions***********************/
void logAndSetParseString(string rule, NonTerminalData* nonTerminalData){
    nonTerminalData->parseTreeString=rule;
    nonTerminalData->parseTreeString+=" \t<Line: ";
    nonTerminalData->parseTreeString+=to_string(nonTerminalData->startLineNumber);
    nonTerminalData->parseTreeString+="-";
    nonTerminalData->parseTreeString+=to_string(nonTerminalData->endLineNumber);
    nonTerminalData->parseTreeString+=">";
    logOutput<<rule<<endl;
}
NonTerminalData* getNonTerminalDataForTerminal(SymbolInfo* symbolInfo){
    NonTerminalData* data=new NonTerminalData();
    data->parseTreeString=symbolInfo->getType();
    data->parseTreeString+=" : ";
    data->parseTreeString+=symbolInfo->getName();
    data->startLineNumber=symbolInfo->getStart();
    data->endLineNumber=symbolInfo->getEnd();
    data->parseTreeString+="\t<Line: ";
    data->parseTreeString+=to_string(data->startLineNumber);
    data->parseTreeString+=">";
    delete symbolInfo;
    return data;
}

void printParseTree(NonTerminalData* nonTerminalData, int indent=0){
    for(int i=0;i<indent;i++){
        parseOutput<<" ";
    }
    parseOutput<<nonTerminalData->parseTreeString<<endl;
    for(auto x:nonTerminalData->expandedParseTree){
        printParseTree(x,indent+1);
    }
    delete nonTerminalData;
}
/***************************End Functions Block*****************/

/******************************Error Handlers Block****************/

void errorIncompatibleFunctionDeclaration(string name, int line){
    errorOutput<<"Line# "<<line<<": Redeclaration of '"<<name<<""<<endl;
    errorCount++;
}

void errorIncompatibleReturnType(string name, int line){
    errorOutput<<"Line# "<<line<<": Conflicting types for '"<<name<<"'"<<endl;
    errorCount++;
}

void errorIncompatibleDeclaration(string name, int line){
    errorOutput<<"Line# "<<line<<": '"<<name<<"' redeclared as different kind of symbol"<<endl;
    errorCount++;
}

void errorMultipleDefinition(string name, int line){
    errorOutput<<"Line# "<<line<<": '"<<name<<"' has been defined previously"<<endl;
    errorCount++;
}

void errorReturnInVoidFunction(string name, int line){
    errorOutput<<"Line# "<<line<<": return statement with a value in function '"<<name<<"' returning a VOID"<<endl;
    errorCount++;
}

void warningDataLoss(int line){
    errorOutput<<"Line# "<<line<<": Warning: possible loss of data in assignment of FLOAT to INT"<<endl;
    errorCount++;
}

void warningIncompatibleReturnType(string functionName, string functionType, string returnType, int line){
    if(functionType=="INT" && returnType=="FLOAT"){
        warningDataLoss(line);
    }
}

void errorRedeclaration(string name, int line, bool isParameter=false){
    if(isParameter)errorOutput<<"Line# "<<line<<": Redefinition of parameter '"<<name<<"'"<<endl;
    else errorOutput<<"Line# "<<line<<": Redeclaration of variable '"<<name<<"'"<<endl;
    errorCount++;
}

void errorRedefinition(string name, int line){
    errorOutput<<"Line# "<<line<<": Conflicting types for '"<<name<<"'"<<endl;
    errorCount++;
}

void errorVoidParameter(string name,int line){
    errorOutput<<"Line# "<<line<<": VOID parameter type for '"<<name<<"'";
    errorCount++;
}


void errorUndeclaredVariable(string name, int line,string type){
    if(type=="ARRAY")errorOutput<<"Line# "<<line<<": Undeclared array '"<<name<<"'"<<endl;
    else if(type=="FUNCTION")errorOutput<<"Line# "<<line<<": Undeclared function '"<<name<<"'"<<endl;
    else errorOutput<<"Line# "<<line<<": Undeclared variable '"<<name<<"'"<<endl;
    errorCount++;
}

void errorReturnOutsideFunction(int line){
    errorOutput<<"Line# "<<line<<": Return statement outside function"<<endl;
    errorCount++;
}
void errorArrayNotIndexed(string name,int line){
    errorOutput<<"Line# "<<line<<": Array '"<<name<<"' not indexed"<<endl;
    errorCount++;
}

void errorFunctionNotCalled(string name,int line){
    errorOutput<<"Line# "<<line<<": Function '"<<name<<"' not called using parameters"<<endl;
    errorCount++;
}

void errorVoidDeclaration(string name, int line){
    errorOutput<<"Line# "<<line<<": Variable or field '"<<name<<"' declared void"<<endl;
    errorCount++;
}

void errorNotArray(string name,int line){
    errorOutput<<"Line# "<<line<<": '"<<name<<"' is not an array"<<endl;
    errorCount++;
}

void errorArrayIndexNotInteger(int line){
    errorOutput<<"Line# "<<line<<": Array subscript is not an integer"<<endl;
    errorCount++;
}

void errorInvalidVoidExpression(int line){
    errorOutput<<"Line# "<<line<<": Void cannot be used in expression"<<endl;
    errorCount++;
}

void errorInvalidVoidAssignment(int line){
    errorInvalidVoidExpression(line);
}

void errorInvalidModulo(int line){
    errorOutput<<"Line# "<<line<<": Operands of modulus must be integers"<<endl;
    errorCount++;
}

void errorDivideByZero(int line){
    errorOutput<<"Line# "<<line<<": Warning: division by zero"<<endl;
    errorCount;
}

void errorNotFunction(string name, int line){
    errorOutput<<"Line# "<<line<<": '"<<name<<"' is not a function"<<endl;
    errorCount++;
}

void errorFunctionNotDefined(string name, int line){
    errorOutput<<"Line# "<<line<<": Function '"<<name<<"' not defined"<<endl;
    errorCount++;
}

void errorInvalidArgumentsNumber(string name, int line, int expected, int found){
    if(expected>found)errorOutput<<"Line# "<<line<<": Too few arguments to function '"<<name<<"'"<<endl;
    else errorOutput<<"Line# "<<line<<": Too many arguments to function '"<<name<<"'"<<endl;
    errorCount++;
}

void errorInvalidArgumentsType(string name, int line, int position){
    errorOutput<<"Line# "<<line<<": Type mismatch for argument "<<position<<" of '"<<name<<"'"<<endl;
    errorCount++;
}

void copyFromTemp(){
    tempCode.close();
    ifstream tempCodeInput("tempCode.asm");
    string line;
    while(getline(tempCodeInput,line)){
        codeOutput<<line<<endl;
    }
}


/******************************End Error Handlers Block****************/

%}

/* %define parse.error verbose */

%union{
    SymbolInfo* symbolInfo;
    NonTerminalData* nonTerminalData;
}

%token LOWER_THAN_ELSE
%token<symbolInfo>IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN 
%token<symbolInfo>LPAREN RPAREN LSQUARE RSQUARE LCURL RCURL COMMA SEMICOLON ASSIGNOP NOT
%token<symbolInfo> ID CONST_INT CONST_FLOAT CONST_CHAR CONST_STRING LOGICOP RELOP ADDOP MULOP INCOP DECOP
%type<nonTerminalData> start program unit var_declaration func_declaration func_definition parameter_list compound_statement
%type<nonTerminalData> type_specifier declaration_list statements statement expression_statement variable expression
%type<nonTerminalData> logic_expression rel_expression simple_expression term unary_expression factor argument_list
%type<nonTerminalData> arguments 
%type enterScope enterFunctionScope
/* %start<nonTerminalData> start */

/* %destructor {/function} <nonTerminalData> */
/* %left 
%right */

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE


%%

start : program
	{
		//write your code in this block in all the similar blocks below
        string rule="start : program";
        $$ = new NonTerminalData();
        $$->endLineNumber=$1->getEnd();
        $$->startLineNumber=$1->getStart();
        $$->expandedParseTree.push_back($1);
        logAndSetParseString(rule,$$);
        printParseTree($$);
        logOutput<<"Total Lines: "<<lineCount<<endl;
        logOutput<<"Total Errors: "<<errorCount<<endl;
        codeOutput<<".CODE"<<endl;
        copyFromTemp();
        codeOutput<<
        "new_line proc\n\tpush ax\n\tpush dx\n\tmov ah,2\n\tmov dl,cr\n\tint 21h\n\tmov ah,2\n\tmov dl,lf\n\tint 21h\n\tpop dx\n\tpop ax\n\tret\nnew_line endp\nprint_output proc  ;print what is in ax\n\tpush ax\n\tpush bx\n\tpush cx\n\tpush dx\n\tpush si\n\tlea si,number\n\tmov bx,10\n\tadd si,4\n\tcmp ax,0\n\tjnge negate\n\tprint:\n\txor dx,dx\n\tdiv bx\n\tmov [si],dl\n\tadd [si],'0'\n\tdec si\n\tcmp ax,0\n\tjne print\n\tinc si\n\tlea dx,si\n\tmov ah,9\n\tint 21h\n\tpop si\n\tpop dx\n\tpop cx\n\tpop bx\n\tpop ax\n\tret\n\tnegate:\n\tpush ax\n\tmov ah,2\n\tmov dl,'-'\n\tint 21h\n\tpop ax\n\tneg ax\n\tjmp print\nprint_output endp\nEND main"<<endl;
        // optimizeCode();
    }
	;

program : program unit
    {
        string rule="program : program unit";
        $$ = new NonTerminalData();
        $$->endLineNumber=$2->getEnd();
        $$->startLineNumber=$1->getStart();
        $$->expandedParseTree.push_back($1);
        $$->expandedParseTree.push_back($2);
        logAndSetParseString(rule,$$);
    }
	| unit
    {
        string rule="program : unit";
        $$ = new NonTerminalData();
        $$->endLineNumber=$1->getEnd();
        $$->startLineNumber=$1->getStart();
        $$->expandedParseTree.push_back($1);
        logAndSetParseString(rule,$$);
    }
	;
	
unit : var_declaration
    {
        string rule="unit : var_declaration";
        $$ = new NonTerminalData();
        $$->endLineNumber=$1->getEnd();
        $$->startLineNumber=$1->getStart();
        $$->expandedParseTree.push_back($1);
        logAndSetParseString(rule,$$);
    }
    | func_declaration
    {
        string rule="unit : func_declaration";
        $$ = new NonTerminalData();
        $$->endLineNumber=$1->getEnd();
        $$->startLineNumber=$1->getStart();
        $$->expandedParseTree.push_back($1);
        logAndSetParseString(rule,$$);
    }
    | func_definition
    {
        string rule="unit : func_definition";
        $$ = new NonTerminalData();
        $$->endLineNumber=$1->getEnd();
        $$->startLineNumber=$1->getStart();
        $$->expandedParseTree.push_back($1);
        logAndSetParseString(rule,$$);
    }
    ;
    
func_declaration : type_specifier ID LPAREN enterFunctionScope parameter_list RPAREN SEMICOLON
        {
            SymbolInfo* temp=table->lookUpInParentScope($2->getName());
            if(temp!=NULL && temp->getIsFunction()){
                auto tempList=temp->getFunctionTypeList();
                if(temp->getType()!=$1->getName())errorIncompatibleReturnType($2->getName(),$1->getStart());
                else if(tempList.size()!=typeList.size()){
                    errorIncompatibleFunctionDeclaration($2->getName(),$1->getStart());
                }
                else{
                    for(int i=0;i<typeList.size();i++){
                        if(typeList[i]!=tempList[i]){
                            errorIncompatibleFunctionDeclaration($2->getName(),$1->getStart());
                            break;
                        }
                    }
                }
                
            }
            else if(temp!=NULL){
                errorIncompatibleDeclaration($2->getName(),$1->getStart());
            }
            SymbolInfo* symbolInfo=new SymbolInfo($2->getName(),$1->getName(),true,false);
            for(auto x:typeList){
                symbolInfo->addFunctionType(x);
            }
            typeList.clear();
            table->insertSymbolInParentScope(symbolInfo);
            table->exitScope();
            table->decreaseScopeId();
            string rule="func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON";
            $$ = new NonTerminalData();
            $$->endLineNumber=$7->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            $$->expandedParseTree.push_back($5);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($6));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($7));
            logAndSetParseString(rule,$$);
            inFunctionScope=false;
        }
		| type_specifier ID LPAREN enterFunctionScope RPAREN SEMICOLON
        {
            SymbolInfo* temp=table->lookUpInParentScope($2->getName());
            if(temp!=NULL && temp->getIsFunction() && temp->getFunctionTypeList().size()!=0){
                errorIncompatibleFunctionDeclaration($2->getName(),$1->getStart());
            }
            else if(temp!=NULL && !temp->getIsFunction()){
                errorIncompatibleDeclaration($2->getName(),$1->getStart());
            }
            table->insertSymbolInParentScope(new SymbolInfo($2->getName(),$1->getName(),true,false));
            table->exitScope();
            table->decreaseScopeId();
            string rule="func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON";
            $$ = new NonTerminalData();
            $$->endLineNumber=$6->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($5));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($6));
            logAndSetParseString(rule,$$);
            inFunctionScope=false;
        }
		;

func_definition : type_specifier ID LPAREN {functionName=$2->getName();}enterFunctionScope parameter_list RPAREN compound_statement
        {
            SymbolInfo* temp=table->lookUpInParentScope($2->getName());
            if(temp!=NULL && temp->getIsFunction()){
                if(temp->getIsDefined()){
                    errorMultipleDefinition($2->getName(),$1->getStart());
                }
                else if(temp->getType()!=$1->getName() || temp->getFunctionTypeList().size()!=typeList.size()){
                    errorIncompatibleReturnType($2->getName(),$1->getStart());
                }
                else{
                    auto tempList=temp->getFunctionTypeList();
                    for(int i=0;i<typeList.size();i++){
                        if(typeList[i]!=tempList[i]){
                            errorIncompatibleFunctionDeclaration($2->getName(),$1->getStart());
                            break;
                        }
                    }
                }
            }
            else if(temp!=NULL && !temp->getIsFunction()){
                errorIncompatibleDeclaration($2->getName(),$1->getStart());
            }
            else if($1->getName()=="VOID" && returnVariableList.size()>0){
                errorReturnInVoidFunction($2->getName(),$1->getStart());
            }
            else{
                for(auto x:returnVariableList){
                    if(x->getName()!=$1->getName()){
                        warningIncompatibleReturnType($2->getName(),$1->getName(),x->getName(),x->getStart());
                    }
                }
            }
            returnVariableList.clear();
            SymbolInfo* symbolInfo=new SymbolInfo($2->getName(),$1->getName(),true,false);
            int returnSize=typeList.size()*2;
            for(auto x:typeList){
                symbolInfo->addFunctionType(x);
            }
            typeList.clear();
            if(temp!=NULL)temp->setIsDefined(true);
            symbolInfo->setIsDefined(true);
            table->insertSymbolInParentScope(symbolInfo);
            table->printAllScope(logOutput);
            table->exitScope();
            tempCode<<"exit_"<<$2->getName()<<":"<<endl;
            tempCode<<"\tMOV SP, BP"<<endl;
            tempCode<<"\tPOP BP"<<endl;
            tempLineCount+=3;
            if(functionName=="main"){
                tempCode<<"\tMOV AX, 4CH"<<endl;
                tempCode<<"\tINT 21H"<<endl;
                tempLineCount+=2;
            }
            else {
                tempCode<<"\tRET "<<returnSize<<endl;
                tempLineCount++;
            }
            tempCode<<$2->getName()<<" ENDP"<<endl;
            tempLineCount++;
            string rule="func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$8->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            $$->expandedParseTree.push_back($6);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($7));
            $$->expandedParseTree.push_back($8);
            logAndSetParseString(rule,$$);
            inFunctionScope=false;
            stackOffset=-2;
            parameterOffset=4;
        }
		| type_specifier ID LPAREN {functionName=$2->getName();} enterFunctionScope RPAREN compound_statement
        {
            SymbolInfo* temp=table->lookUpInParentScope($2->getName());
            if(temp!=NULL && temp->getIsFunction()){
                if(temp->getIsDefined()){
                    errorMultipleDefinition($2->getName(),$1->getStart());
                }
                else if(temp->getType()!=$1->getName()){
                    errorIncompatibleReturnType($2->getName(),$1->getStart());
                }
                else if(temp->getFunctionTypeList().size()!=0){
                    errorIncompatibleFunctionDeclaration($2->getName(),$1->getStart());
                }
            }
            else if(temp!=NULL && !temp->getIsFunction()){
                errorIncompatibleDeclaration($2->getName(),$1->getStart());
            }
            else if($1->getName()=="VOID" && returnVariableList.size()>0){
                errorReturnInVoidFunction($2->getName(),$1->getStart());
            }
            else{
                for(auto x:returnVariableList){
                    if(x->getName()!=$1->getName()){
                        warningIncompatibleReturnType($2->getName(),$1->getName(),x->getName(),x->getStart());
                    }
                }
            }
            tempCode<<"exit_"<<$2->getName()<<":"<<endl;
            tempCode<<"\tMOV SP, BP"<<endl;
            tempCode<<"\tPOP BP"<<endl;
            tempLineCount+=3;
            if(functionName=="main"){
                tempCode<<"\tMOV AX, 4CH"<<endl;
                tempCode<<"\tINT 21H"<<endl;
                tempLineCount+=2;
            }
            else tempCode<<"\tRET"<<endl;
            tempLineCount++;
            tempCode<<$2->getName()<<" ENDP"<<endl;
            tempLineCount++;
            returnVariableList.clear();
            SymbolInfo* symbolInfo=new SymbolInfo($2->getName(),$1->getName(),true,false);
            if(temp!=NULL)temp->setIsDefined(true);
            symbolInfo->setIsDefined(true);
            table->insertSymbolInParentScope(symbolInfo);
            table->printAllScope(logOutput);
            table->exitScope();
            string rule="func_definition : type_specifier ID LPAREN RPAREN compound_statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$7->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($6));
            $$->expandedParseTree.push_back($7);
            logAndSetParseString(rule,$$);
            inFunctionScope=false;
            stackOffset=-2;
            parameterOffset=4;
        }
        ;				


parameter_list  : parameter_list COMMA type_specifier ID
        {
            SymbolInfo* temp=table->lookUpInCurrentScope($4->getName());
            if(temp!=NULL){
                if(temp->getType()!=$3->getName()) errorRedefinition($4->getName(),$4->getStart());
                else errorRedeclaration($4->getName(),$4->getStart(),true);
            }
            else if($3->getName()=="VOID") errorVoidParameter($4->getName(),$4->getStart());
            if(!inFunctionScope)table->insertSymbol($4->getName(),$3->getName());
            else {
                SymbolInfo* temp=new SymbolInfo($4->getName(),$3->getName(),false, parameterOffset);
                table->insertSymbol(temp);
                parameterOffset+=2;
            }
            typeList.push_back($3->getName());
            string rule="parameter_list : parameter_list COMMA type_specifier ID";
            $$ = new NonTerminalData();
            $$->endLineNumber=$4->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            logAndSetParseString(rule,$$);
        }
		| parameter_list COMMA type_specifier
        {
            if($3->getName()=="VOID") errorVoidParameter($3->getName(),$3->getStart());;
            typeList.push_back($3->getName());
            string rule="parameter_list : parameter_list COMMA type_specifier";
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            logAndSetParseString(rule,$$);
        }
        | type_specifier ID
        {
            SymbolInfo* temp=table->lookUpInCurrentScope($2->getName());
            if(temp!=NULL){
                if(temp->getType()!=$1->getName()) errorRedefinition($2->getName(),$2->getStart());
                else errorRedeclaration($2->getName(),$2->getStart(),true);
            }
            else if($1->getName()=="VOID") errorVoidParameter($1->getName(),$1->getStart());
            if(!inFunctionScope)table->insertSymbol($2->getName(),$1->getName());
            else {
                SymbolInfo* temp=new SymbolInfo($2->getName(),$1->getName(),false, parameterOffset);
                table->insertSymbol(temp);
                parameterOffset+=2;
            }
            typeList.push_back($1->getName());
            string rule="parameter_list : type_specifier ID";
            $$ = new NonTerminalData();
            $$->endLineNumber=$2->getEnd();
            $$->startLineNumber=$1->startLineNumber;
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            logAndSetParseString(rule,$$);
        }
		| type_specifier
        {
            typeList.push_back($1->getName());
            string rule="parameter_list : type_specifier";
            $$ = new NonTerminalData();
            $$->endLineNumber=lineCount;
            $$->startLineNumber=$1->startLineNumber;
            $$->expandedParseTree.push_back($1);
            logAndSetParseString(rule,$$); 
        }
        ;

compound_statement : LCURL enterScope statements RCURL
        {
            if(exitScopeFlag){
                table->printAllScope(logOutput);
                table->exitScope();
                exitScopeFlag--;
            }
            string rule="compound_statement : LCURL statements RCURL";
            $$ = new NonTerminalData();
            $$->endLineNumber=$4->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back($3);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            logAndSetParseString(rule,$$);
        }
        | LCURL RCURL
        {
            string rule="compound_statement : LCURL RCURL";
            $$ = new NonTerminalData();
            $$->endLineNumber=$2->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            logAndSetParseString(rule,$$);
        }
        ;

var_declaration : type_specifier declaration_list SEMICOLON
        {
            string rule="var_declaration : type_specifier declaration_list SEMICOLON";
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back($2);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            logAndSetParseString(rule,$$);
        }
        ;

type_specifier	: INT
        {
            string rule="type_specifier : INT";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            type="INT";
            $$->name="INT";
            logAndSetParseString(rule,$$);
        }
        | FLOAT
        {
            string rule="type_specifier : FLOAT";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            type="FLOAT";
            $$->name="FLOAT";
            logAndSetParseString(rule,$$);
        }
        | VOID
        {
            string rule="type_specifier : VOID";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            type="VOID";
            $$->name="VOID";
            logAndSetParseString(rule,$$);
        }
        ;

declaration_list : declaration_list COMMA ID
        {
            SymbolInfo* temp=table->lookUpInCurrentScope($3->getName());
            if(temp!=NULL){
                if(temp->getType()==type || temp->getIsFunction()||temp->getIsArray())errorRedeclaration($3->getName(),$3->getStart());
                else errorRedefinition($3->getName(),$3->getStart());
            }
            else if(type=="VOID")errorVoidDeclaration($3->getName(),$3->getStart());
            string rule="declaration_list : declaration_list COMMA ID";
            if(inFunctionScope){
                tempCode<<"\tSUB SP, 2"<<endl;
                tempLineCount++;
                SymbolInfo* temp=new SymbolInfo($3->getName(),type,false, stackOffset);
                table->insertSymbol(temp);
                stackOffset-=2;
            }
            else {
                codeOutput<<"\t"<<$3->getName()<<" DW 1 DUP (0000H)"<<endl;
                table->insertSymbol($3->getName(),type);
            }
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            logAndSetParseString(rule,$$);
        }
        | declaration_list COMMA ID LSQUARE CONST_INT RSQUARE
        {
            SymbolInfo* temp=table->lookUpInCurrentScope($3->getName());
            if(temp!=NULL){
                if(!temp->getIsArray())errorIncompatibleDeclaration($3->getName(),$3->getStart());
                else if(temp->getType()==type)errorRedeclaration($3->getName(),$3->getStart());
                else errorRedefinition($3->getName(),$3->getStart());
            }
            else if(type=="VOID")errorVoidDeclaration($3->getName(),$3->getStart());
            string rule="declaration_list : declaration_list COMMA ID LSQUARE CONST_INT RSQUARE";
            if(inFunctionScope){
                tempCode<<"\tSUB SP, "<<2*stoi($5->getName())<<endl;
                tempLineCount++;
                SymbolInfo* temp=new SymbolInfo($3->getName(),type,false, stackOffset,false,true);
                table->insertSymbol(temp);
                stackOffset-=2*stoi($5->getName());
            }
            else {
                codeOutput<<"\t"<<$3->getName()<<" DW "<<$5->getName()<<" DUP (0000H)"<<endl;
                SymbolInfo* temp=new SymbolInfo($3->getName(),type,false,true);
                table->insertSymbol(temp);
            }
            $$ = new NonTerminalData();
            $$->endLineNumber=$6->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($5));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($6));
            logAndSetParseString(rule,$$);
        }
        | ID
        {
            SymbolInfo* temp=table->lookUpInCurrentScope($1->getName());
            if(temp!=NULL){
                if(temp->getType()==type || temp->getIsFunction()||temp->getIsArray())errorRedeclaration($1->getName(),$1->getStart());
                else errorRedefinition($1->getName(),$1->getStart());
            }
            else if(type=="VOID")errorVoidDeclaration($1->getName(),$1->getStart());
            if(inFunctionScope){
                tempCode<<"\tSUB SP, 2"<<endl;
                tempLineCount++;
                SymbolInfo* temp=new SymbolInfo($1->getName(),type,false, stackOffset);
                table->insertSymbol(temp);
                stackOffset-=2;
            }
            else {
                codeOutput<<"\t"<<$1->getName()<<" DW 1 DUP (0000H)"<<endl;
                table->insertSymbol($1->getName(),type);
            }
            string rule="declaration_list : ID";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            logAndSetParseString(rule,$$);
        }
        | ID LSQUARE CONST_INT RSQUARE
        {
            SymbolInfo* temp=table->lookUpInCurrentScope($1->getName());
            if(temp!=NULL){
                if(!temp->getIsArray())errorIncompatibleDeclaration($1->getName(),$1->getStart());
                else if(temp->getType()==type || temp->getIsFunction())errorRedeclaration($1->getName(),$1->getStart());
                else errorRedefinition($1->getName(),$1->getStart());
            }
            else if(type=="VOID")errorVoidDeclaration($1->getName(),$1->getStart());
            if(inFunctionScope){
                tempCode<<"\tSUB SP, "<<2*stoi($3->getName())<<endl;
                tempLineCount++;
                SymbolInfo* temp=new SymbolInfo($1->getName(),type,false, stackOffset,false,true);
                table->insertSymbol(temp);
                stackOffset-=2*stoi($3->getName());
            }
            else {
                codeOutput<<"\t"<<$1->getName()<<" DW "<<$3->getName()<<" DUP (0000H)"<<endl;
                SymbolInfo* temp=new SymbolInfo($1->getName(),type,false,true);
                table->insertSymbol(temp);
            }
            string rule="declaration_list : ID LSQUARE CONST_INT RSQUARE";
            $$ = new NonTerminalData();
            $$->endLineNumber=$4->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            logAndSetParseString(rule,$$);
        }
        ;

statements : statement
        {
            string rule="statements : statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            logAndSetParseString(rule,$$);
        }
        | statements statement
        {
            string rule="statements : statements statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$2->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back($2);
            logAndSetParseString(rule,$$);
        }
        ;

statement : var_declaration
        {
            string rule="statement : var_declaration";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            logAndSetParseString(rule,$$);
        }
        | expression_statement
        {
            string rule="statement : expression_statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            logAndSetParseString(rule,$$);
        }
        | compound_statement
        {
            string rule="statement : compound_statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            logAndSetParseString(rule,$$);
        }
        | FOR LPAREN {enterScopeFlag=false;table->enterScope();} expression_statement expression_statement expression RPAREN statement
        {
            table->printAllScope(logOutput);
            table->exitScope();
            string rule="statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$8->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($4);
            $$->expandedParseTree.push_back($5);
            $$->expandedParseTree.push_back($6);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($7));
            $$->expandedParseTree.push_back($8);
            logAndSetParseString(rule,$$);
            enterScopeFlag=true;
        }
        | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
        {
            string rule="statement : IF LPAREN expression RPAREN statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$5->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            $$->expandedParseTree.push_back($5);
            logAndSetParseString(rule,$$);
        }
        | IF LPAREN expression RPAREN statement ELSE statement
        {
            string rule="statement : IF LPAREN expression RPAREN statement ELSE statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$7->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            $$->expandedParseTree.push_back($5);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($6));
            $$->expandedParseTree.push_back($7);
            logAndSetParseString(rule,$$);
        }
        | WHILE LPAREN expression RPAREN statement
        {
            string rule="statement : WHILE LPAREN expression RPAREN statement";
            $$ = new NonTerminalData();
            $$->endLineNumber=$5->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            $$->expandedParseTree.push_back($5);
            logAndSetParseString(rule,$$);
        }
        | PRINTLN LPAREN ID RPAREN SEMICOLON
        {
            SymbolInfo* temp=table->lookUpSymbol($3->getName());
            if(temp==NULL){
                errorUndeclaredVariable($3->getName(),$3->getStart(),"VARIABLE");
            }
            string rule="statement : PRINTLN LPAREN ID RPAREN SEMICOLON";
            if(temp->getIsGlobal())tempCode<<"\tMOV AX, "<<temp->getName()<<endl;
            else {
                int offset=temp->getStackOffset();
                if(offset>0)tempCode<<"\tMOV AX, [BP+"<<offset<<"]\n";
                else tempCode<<"\tMOV AX, [BP"<<offset<<"]\n";
            }
            tempCode<<"\tCALL print_output\n";
            tempCode<<"\tCALL new_line\n";
            tempLineCount+=3;
            $$ = new NonTerminalData();
            $$->endLineNumber=$5->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($5));
            logAndSetParseString(rule,$$);
        }
        | RETURN expression SEMICOLON
        {
            if(!inFunctionScope){
                errorReturnOutsideFunction($1->getStart());
            }
            returnVariableList.push_back($2);
            string rule="statement : RETURN expression SEMICOLON";
            tempCode<<"\tJMP exit_"<<functionName<<endl;
            tempLineCount++;
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back($2);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            logAndSetParseString(rule,$$);
        }
        ;

expression_statement 	: SEMICOLON		
        {
            tempCode<<"\tPOP AX"<<endl;
            tempLineCount++;
            string rule="expression_statement : SEMICOLON";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            logAndSetParseString(rule,$$);
        }
		| expression SEMICOLON 
        {
            tempCode<<"\tPOP AX"<<endl;
            tempLineCount++;
            string rule="expression_statement : expression SEMICOLON";
            $$ = new NonTerminalData();
            $$->endLineNumber=$2->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            logAndSetParseString(rule,$$);
        }
		;

variable : ID 
        {
            SymbolInfo* symbol=table->lookUpSymbol($1->getName());
            if(symbol==NULL){
                errorUndeclaredVariable($1->getName(),$1->getStart(),"VARIABLE");
            }
            else if(symbol->getIsArray()){
                errorArrayNotIndexed($1->getName(),$1->getStart());
            }
            else if(symbol->getIsFunction()){
                errorFunctionNotCalled($1->getName(),$1->getStart());
            }
            else if(symbol->getType()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            string rule="variable : ID";
            $$ = new NonTerminalData();
            $$->symbolInfo=symbol;
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            if(symbol!=NULL)$$->name=symbol->getType();
            else $$->name="ERROR";
            $$->symbolInfo=symbol;
            logAndSetParseString(rule,$$);
        }
        | ID LSQUARE expression RSQUARE 
        {
            SymbolInfo* symbol=table->lookUpSymbol($1->getName());
            if(symbol==NULL){
                errorUndeclaredVariable($1->getName(),$1->getStart(),"ARRAY");
            }
            else if(!symbol->getIsArray()){
                errorNotArray($1->getName(),$1->getStart());
            }
            else if($3->getName()!="INT"){
                errorArrayIndexNotInteger($3->getStart());
            }
            string rule="variable : ID LSQUARE expression RSQUARE";
            $$ = new NonTerminalData();
            $$->symbolInfo=symbol;
            $$->endLineNumber=$4->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            if(symbol!=NULL)$$->name=symbol->getType();
            else $$->name="ERROR";
            logAndSetParseString(rule,$$);
        }
        ;

expression : logic_expression
        {
            string rule="expression : logic_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->name=$1->getName();
            logAndSetParseString(rule,$$);
        }
        | variable ASSIGNOP logic_expression 
        {
            SymbolInfo* symbol=$1->symbolInfo;
            if($3->getName()=="VOID"){
                errorInvalidVoidAssignment($3->getStart());
            }
            if($1->getName()=="INT" && $3->getName()=="FLOAT"){
                warningDataLoss($1->getStart());
            }
            if(symbol->getIsArray()){
                tempCode<<"\tPOP AX\n";
                tempCode<<"\tPOP BX\n";
                tempCode<<"\tSHL BX, 1\n";
                tempLineCount+=3;
                if(symbol->getIsGlobal()){
                    tempCode<<"\tMOV BYTE PTR "<<symbol->getName()<<"[BX], AX"<<endl;
                    tempLineCount++;    
                }
                else{
                    int offset=symbol->getStackOffset();
                    tempCode<<"\tMOV SI, BX\n";
                    tempLineCount++;
                    if(offset>0){
                        tempCode<<"\tADD SI, "<<offset<<endl;
                        tempLineCount++;
                    }
                    else {
                        tempCode<<"\tADD SI, "<<-offset<<endl;
                        tempCode<<"\tNEG SI\n";
                        tempLineCount+=2;
                    }
                    tempCode<<"\tMOV [BP+SI], AX"<<endl;
                    tempLineCount++;
                } 
            }
            else{
                tempCode<<"\tPOP AX\n";
                if(symbol->getIsGlobal())tempCode<<"\tMOV "<<symbol->getName()<<", AX"<<endl;
                else{
                    int offset=symbol->getStackOffset();
                    if(offset>0)tempCode<<"\tMOV [BP+"<<offset<<"], AX \n";
                    if(offset<0)tempCode<<"\tMOV [BP"<<offset<<"], AX\n";
                }
                tempLineCount+=2;
            }
            tempCode<<"\tPUSH AX\n";
            tempLineCount++;
            string rule="expression : variable ASSIGNOP logic_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->name=$1->getName();
            logAndSetParseString(rule,$$);
        }
        ;
			
logic_expression : rel_expression 	
        {
            string rule="logic_expression : rel_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->name=$1->getName();
            logAndSetParseString(rule,$$);
        }
        | rel_expression LOGICOP rel_expression 
        {
            if($1->getName()=="VOID" || $3->getName()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            string rule="logic_expression : rel_expression LOGICOP rel_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->name="INT";
            logAndSetParseString(rule,$$);
        }	
        ;
			
rel_expression	: simple_expression 
        {
            string rule="rel_expression : simple_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->name=$1->getName();
            logAndSetParseString(rule,$$);
        }
		| simple_expression RELOP simple_expression	
        {
            if($1->getName()=="VOID" || $3->getName()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            string rule="rel_expression : simple_expression RELOP simple_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->name="INT";
            logAndSetParseString(rule,$$);
        }
		;
				
simple_expression : term 
        {
            string rule="simple_expression : term";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->name=$1->getName();
            logAndSetParseString(rule,$$);
        }
        | simple_expression ADDOP term 
        {
            if($1->getName()=="VOID" || $3->getName()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            string rule="simple_expression : simple_expression ADDOP term";
            $$ = new NonTerminalData();
            tempCode<<"\tPOP BX\n";
            tempCode<<"\tPOP AX\n";
            if($2->getName()=="+")tempCode<<"\tADD AX, BX\n";
            else tempCode<<"\tSUB AX, BX\n";
            tempCode<<"\tPUSH AX\n";
            tempLineCount+=4;
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            if($1->getName()=="FLOAT" || $3->getName()=="FLOAT"){
                $$->name="FLOAT";
            }
            else{
                $$->name="INT";
            }
            logAndSetParseString(rule,$$);
        }
        ;

term :	unary_expression
        {
            string rule="term : unary_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->name=$1->getName();
            logAndSetParseString(rule,$$);
        }
        | term MULOP unary_expression
        {
            if($1->getName()=="VOID" || $3->getName()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            else if(($1->getName()=="FLOAT" || $3->getName()=="FLOAT")&& $2->getName()=="%"){
                errorInvalidModulo($1->getStart());
            }
            else if($2->getName()!="*" && $3->value==0){
                errorDivideByZero($1->getStart());
            }
            string rule="term : term MULOP unary_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            if($2->getName()=="%"){
                $$->name="INT";
            }
            else if($1->getName()=="FLOAT" || $3->getName()=="FLOAT"){
                $$->name="FLOAT";
            }
            else{
                $$->name="INT";
            }
            tempCode<<"\tPOP BX\n";
            tempCode<<"\tPOP AX\n";
            tempCode<<"\tCWD\n";
            if($2->getName()=="*"){
                tempCode<<"\tMUL BX\n";
                tempCode<<"\tPUSH AX\n";
            }
            else if($2->getName()=="/"){
                tempCode<<"\tDIV BX\n";
                tempCode<<"\tPUSH AX\n";
            }
            else if($2->getName()=="%"){
                tempCode<<"\tDIV BX\n";
                tempCode<<"\tPUSH DX\n";
            }
            tempLineCount+=5;
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            logAndSetParseString(rule,$$);
        }
        ;

unary_expression : ADDOP unary_expression 
        {
            if($2->getName()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            string rule="unary_expression : ADDOP unary_expression";
            if($1->getName()=="-"){
                tempCode<<"\tPOP AX\n";
                tempCode<<"\tNEG AX\n";
                tempCode<<"\tPUSH AX\n";
                tempLineCount+=3;
            }
            $$ = new NonTerminalData();
            $$->endLineNumber=$2->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back($2);
            $$->name=$2->getName();
            logAndSetParseString(rule,$$);
        }
        | NOT unary_expression 
        {
            if($2->getName()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            string rule="unary_expression : NOT unary_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$2->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back($2);
            $$->name="INT";
            logAndSetParseString(rule,$$);
        }
        | factor 
        {
            string rule="unary_expression : factor";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->name=$1->getName();
            $$->value=$1->getValue();
            logAndSetParseString(rule,$$);
        }
        ;
	
factor	: variable 
        {
            string rule="factor : variable";
            SymbolInfo* symbol = $1->symbolInfo;
            if(symbol->getIsArray()){
                tempCode<<"\tPOP BX"<<endl;
                tempCode<<"\tSHL BX, 1"<<endl;
                tempLineCount+=2;
                if(symbol->getIsGlobal()){
                    tempCode<<"\tMOV AX, "<<symbol->getName()<<"[BX]\n";
                    tempLineCount++;
                }
                else{
                    int offset=symbol->getStackOffset();
                    tempCode<<"\tMOV SI, BX\n";
                    tempLineCount++;
                    if(offset>0){
                        tempCode<<"\tADD SI, "<<offset<<endl;
                        tempLineCount++;
                    }
                    else {
                        tempCode<<"\tADD SI, "<<-offset<<endl;
                        tempCode<<"\tNEG SI\n";
                        tempLineCount+=2;
                    }
                    tempCode<<"\tMOV AX, [BP+SI]\n";
                    tempLineCount++;
                }
            }
            else{
                if(symbol->getIsGlobal()){
                    tempCode<<"\tMOV AX, "<<symbol->getName()<<"\n";
                }
                else{
                    int offset=symbol->getStackOffset();
                    if(offset>0)tempCode<<"\tMOV AX, [BP+"<<offset<<"]\n";
                    if(offset<0)tempCode<<"\tMOV AX, [BP"<<offset<<"]\n";
                }
                tempLineCount++;
            }
            tempCode<<"\tPUSH AX\n";
            tempLineCount++;
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->name=$1->getName();
            logAndSetParseString(rule,$$);
        }
        | ID LPAREN argument_list RPAREN
        {
            SymbolInfo* symbolInfo = table->lookUpSymbol($1->getName());
            if(symbolInfo==NULL){
                errorUndeclaredVariable($1->getName(),$1->getStart(),"FUNCTION");
            }
            else if(!symbolInfo->getIsFunction()){
                errorNotFunction($1->getName(),$1->getStart());
            }
            else if(symbolInfo->getFunctionTypeList().size()!=$3->functionTypeList.size()){
                errorInvalidArgumentsNumber($1->getName(),$1->getStart(),symbolInfo->getFunctionTypeList().size(),$3->functionTypeList.size());
            }
            else{
                vector<string> functionTypeList = symbolInfo->getFunctionTypeList();
                for(int i=0;i<functionTypeList.size();i++){
                    if(functionTypeList[i]!=$3->functionTypeList[i]){
                        errorInvalidArgumentsType($1->getName(),$1->getStart(),i+1);
                    }
                }
            }
            tempCode<<"\tCALL "<<$1->getName()<<"\n";
            tempCode<<"\tPUSH AX\n";
            tempLineCount+=2;
            string rule="factor : ID LPAREN argument_list RPAREN";
            $$ = new NonTerminalData();
            $$->endLineNumber=$4->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($4));
            if(symbolInfo!=NULL)$$->name=symbolInfo->getType();
            else $$->name="ERROR";
            logAndSetParseString(rule,$$);
        }
        | LPAREN expression RPAREN
        {
            string rule="factor : LPAREN expression RPAREN";
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            $$->expandedParseTree.push_back($2);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($3));
            $$->name=$2->getName();
            logAndSetParseString(rule,$$);
        }
        | CONST_INT 
        {
            string rule="factor : CONST_INT";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->name="INT";
            $$->value=stoi($1->getName());
            tempCode<<"\tMOV AX,"<<$$->value<<endl;
            tempCode<<"\tPUSH AX"<<endl;
            tempLineCount+=2;
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            logAndSetParseString(rule,$$);
        }
        | CONST_FLOAT
        {
            string rule="factor : CONST_FLOAT";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->name="FLOAT";
            $$->value=stof($1->getName());
            tempCode<<"\tMOV AX,"<<$$->value<<endl;
            tempCode<<"\tPUSH AX"<<endl;
            tempLineCount+=2;
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($1));
            logAndSetParseString(rule,$$);
        }
        | variable INCOP 
        {
            if($1->getName()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            string rule="factor : variable INCOP";
            SymbolInfo* symbol = $1->symbolInfo;
            if(symbol->getIsArray()){
                tempCode<<"\tPOP BX"<<endl;
                tempCode<<"\tSHL BX, 1"<<endl;
                tempLineCount+=2;
                if(symbol->getIsGlobal()){
                    tempCode<<"\tMOV AX, "<<symbol->getName()<<"[BX]\n";
                    tempCode<<"\tINC AX\n";
                    tempCode<<"\tMOV "<<symbol->getName()<<"[BX], AX\n";
                    tempLineCount+=3;
                }
                else{
                    int offset=symbol->getStackOffset();
                    tempCode<<"\tMOV SI, BX\n";
                    tempLineCount++;
                    if(offset>0){
                        tempCode<<"\tADD SI, "<<offset<<endl;
                        tempLineCount++;
                    }
                    else {
                        tempCode<<"\tADD SI, "<<-offset<<endl;
                        tempCode<<"\tNEG SI\n";
                        tempLineCount+=2;
                    }
                    tempCode<<"\tMOV AX, [BP+SI]\n";
                    tempCode<<"\tINC AX\n";
                    tempCode<<"\tMOV [BP+SI], AX\n";
                    tempLineCount+=3;
                }
            }
            else{
                if(symbol->getIsGlobal()){
                    tempCode<<"\tMOV AX, "<<symbol->getName()<<"\n";
                    tempCode<<"\tINC AX\n";
                    tempCode<<"\tMOV "<<symbol->getName()<<", AX\n";
                }
                else{
                    int offset=symbol->getStackOffset();
                    if(offset>0){
                        tempCode<<"\tMOV AX, [BP+"<<offset<<"]\n";
                        tempCode<<"\tINC AX\n";
                        tempCode<<"\tMOV [BP+"<<offset<<"], AX\n";
                    }
                    if(offset<0){
                        tempCode<<"\tMOV AX, [BP"<<offset<<"]\n";
                        tempCode<<"\tINC AX\n";
                        tempCode<<"\tMOV [BP"<<offset<<"], AX\n";
                    }
                }
                tempLineCount+=3;
            }
            tempCode<<"\tPUSH AX\n";
            tempLineCount++;
            $$ = new NonTerminalData();
            $$->endLineNumber=$2->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->name=$1->getName();
            logAndSetParseString(rule,$$);
        }
        | variable DECOP
        {
            if($1->getName()=="VOID"){
                errorInvalidVoidExpression($1->getStart());
            }
            string rule="factor : variable DECOP";
            SymbolInfo* symbol = $1->symbolInfo;
            if(symbol->getIsArray()){
                tempCode<<"\tPOP BX"<<endl;
                tempCode<<"\tSHL BX, 1"<<endl;
                tempLineCount+=2;
                if(symbol->getIsGlobal()){
                    tempCode<<"\tMOV AX, "<<symbol->getName()<<"[BX]\n";
                    tempCode<<"\tINC AX\n";
                    tempCode<<"\tMOV "<<symbol->getName()<<"[BX], AX\n";
                    tempLineCount+=3;
                }
                else{
                    int offset=symbol->getStackOffset();
                    tempCode<<"\tMOV SI, BX\n";
                    tempLineCount++;
                    if(offset>0){
                        tempCode<<"\tADD SI, "<<offset<<endl;
                        tempLineCount++;
                    }
                    else {
                        tempCode<<"\tADD SI, "<<-offset<<endl;
                        tempCode<<"\tNEG SI\n";
                        tempLineCount+=2;
                    }
                    tempCode<<"\tMOV AX, [BP+SI]\n";
                    tempCode<<"\tDEC AX\n";
                    tempCode<<"\tMOV [BP+SI], AX\n";
                    tempLineCount+=3;
                }
            }
            else{
                if(symbol->getIsGlobal()){
                    tempCode<<"\tMOV AX, "<<symbol->getName()<<"\n";
                    tempCode<<"\tINC AX\n";
                    tempCode<<"\tMOV "<<symbol->getName()<<", AX\n";
                }
                else{
                    int offset=symbol->getStackOffset();
                    if(offset>0){
                        tempCode<<"\tMOV AX, [BP+"<<offset<<"]\n";
                        tempCode<<"\tINC AX\n";
                        tempCode<<"\tMOV [BP+"<<offset<<"], AX\n";
                    }
                    if(offset<0){
                        tempCode<<"\tMOV AX, [BP"<<offset<<"]\n";
                        tempCode<<"\tDEC AX\n";
                        tempCode<<"\tMOV [BP"<<offset<<"], AX\n";
                    }
                }
                tempLineCount+=3;
            }
            tempCode<<"\tPUSH AX\n";
            tempLineCount++;
            $$ = new NonTerminalData();
            $$->endLineNumber=$2->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->name=$1->getName(); 
            logAndSetParseString(rule,$$);
        }
        ;
	
argument_list : arguments
        {
            string rule="argument_list : arguments";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->functionTypeList=$1->functionTypeList;
            logAndSetParseString(rule,$$);
        }
        |
        {
            string rule="argument_list : ";
            $$ = new NonTerminalData();
            $$->endLineNumber=lineCount;
            $$->startLineNumber=lineCount;
            logAndSetParseString(rule,$$);
        }
        ;
	
arguments : arguments COMMA logic_expression
        {
            string rule="arguments : arguments COMMA logic_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$3->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->expandedParseTree.push_back(getNonTerminalDataForTerminal($2));
            $$->expandedParseTree.push_back($3);
            $$->functionTypeList=$1->functionTypeList;
            $$->functionTypeList.push_back($3->getName());
            logAndSetParseString(rule,$$);
        }
        | logic_expression
        {
            string rule="arguments : logic_expression";
            $$ = new NonTerminalData();
            $$->endLineNumber=$1->getEnd();
            $$->startLineNumber=$1->getStart();
            $$->expandedParseTree.push_back($1);
            $$->functionTypeList.push_back($1->getName());
            logAndSetParseString(rule,$$);
        }
        ;

enterFunctionScope :
        {
            table->enterScope();
            inFunctionScope=true;
            enterScopeFlag=false;
            tempCode<<functionName<<" PROC"<<endl;
            tempLineCount++;
            if(functionName=="main"){
                tempCode<<"\tMOV AX, @DATA\n\tMOV DS, AX"<<endl;
                tempLineCount+=2;
            }
            tempCode<<"\tPUSH BP\n\tMOV BP, SP"<<endl;
            tempLineCount+=2;
        }
        ;

enterScope :
        {
            if(!enterScopeFlag)enterScopeFlag=true;
            else {
                table->enterScope();
                exitScopeFlag++;
            }
        }
        ;


%%
int main(int argc,char *argv[])
{
    FILE *fileInput=fopen(argv[1],"r");
	if(fileInput==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
    parseOutput.open("1905026_parse.txt");
	errorOutput.open("1905026_error.txt");
	logOutput.open("1905026_log.txt");
    codeOutput.open("1905026_code.asm");
    optimizedCodeOutput.open("1905026_optimized_code.asm");
    tempCode.open("tempCode.asm");
    codeOutput<<".MODEL SMALL\n.STACK 1000H\n.Data\nCR EQU 0DH\nLF EQU 0AH\nnumber DB \"00000$\""<<endl;
	yyin=fileInput;
	yyparse();
	fclose(fileInput);
    parseOutput.close();
    errorOutput.close();
    logOutput.close();
    codeOutput.close();
    optimizedCodeOutput.close();
    remove("tempCode.asm");
	delete table;
	return 0;
}

