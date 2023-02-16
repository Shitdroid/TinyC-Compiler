#include <fstream>
#include <string>
#include "ScopeTable.h"

class SymbolTable{
    ScopeTable *currentScope;
    int size,id=1;
public:
    //constructor
    SymbolTable(int size){
        this->size=size;
        currentScope=new ScopeTable(size,id++,NULL);
    }
    //destructor
    ~SymbolTable(){
        while(currentScope!=NULL){
            ScopeTable *temp=currentScope->getParentScope();
            delete currentScope;
            currentScope=temp;
        }
    }

    //enter Scope
    void enterScope(){
        ScopeTable *temp=new ScopeTable(size,id++,currentScope);
        currentScope=temp;
    }

    //exit Scope
    void exitScope(){
        if(currentScope->getId()==1){
            return;
        }
        ScopeTable *temp=currentScope;
        currentScope=currentScope->getParentScope();
        delete temp;
    }

    //insert
    bool insertSymbol(std::string name,std::string type){
        return currentScope->insertSymbol(name,type);
    }

    bool insertSymbol(SymbolInfo* symbol){
        return currentScope->insertSymbol(symbol);
    }

    bool insertSymbolInParentScope(SymbolInfo* symbol){
        return currentScope->getParentScope()->insertSymbol(symbol);
    }

    //remove
    bool removeSymbol(std::string name){
        return currentScope->deleteSymbol(name);
    }

    //look up
    SymbolInfo* lookUpSymbol(std::string name){
        ScopeTable *temp=currentScope;
        while(temp!=NULL){
            SymbolInfo *temp2=temp->lookUpSymbol(name);
            if(temp2==NULL){
                temp=temp->getParentScope();
            }
            else{
                return temp2;
            }
        }
        return NULL;
    }
    
    SymbolInfo* lookUpInParentScope(std::string name){
        return currentScope->getParentScope()->lookUpSymbol(name);
    }

    SymbolInfo* lookUpInCurrentScope(std::string name){
        return currentScope->lookUpSymbol(name);
    }

    //print Current Scope
    void printCurrentScope(std::ofstream &out){
        currentScope->printTable(out);
    }

    //print All Scope
    void printAllScope(std::ofstream &out){
        ScopeTable *temp=currentScope;
        while(temp!=NULL){
            temp->printTable(out);
            temp=temp->getParentScope();
        }
    }

    void decreaseScopeId(){
        id--;
    }
};