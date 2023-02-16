%option noyywrap

%x MULTI_COMMENT_STATE

%{

#include<bits/stdc++.h>

#include "SymbolTable.h"
#include "NonTerminalData.h"
#include "y.tab.h"

using namespace std;

extern YYSTYPE yylval;
void yyerror(char *);

extern int lineCount;
extern int errorCount;

string comment;

extern ofstream logOutput;
extern ofstream errOutput;


int countNewLines(string str){
	int count = 0;
	for(int i=0;i<str.length();i++){
		if(str[i]=='\n')
			count++;
	}
	return count;
}

/*get actual string from the string literal*/
string getPrintableString(string str){
	string result = "";
	for(int i=0;i<str.length();i++){
		if(str[i]=='\\'){
			if(str[i+1]=='n')
				result += '\n';
			if(str[i+1]=='t')
				result += '\t';
			if(str[i+1]=='a')
				result += '\a';
			if(str[i+1]=='f')
				result += '\f';
			if(str[i+1]=='r')
				result += '\r';
			if(str[i+1]=='b')
				result += '\b';
			if(str[i+1]=='v')
				result += '\v';
			if(str[i+1]=='0')
				result += '\0';
			if(str[i+1]=='\\')
				result += '\\';
			if(str[i+1]=='\'')
				result += '\'';
			if(str[i+1]=='\"')
				result += '\"';
			if(str[i]=='\n')
				lineCount++;
			i++;
		}
		else result += str[i];
	}
	return result;
}

%}

WHITESPACE [ \t\f\r\v]+ 
LETTER [a-zA-Z_]
DIGIT [0-9]
ALPHA_NUMERIC [a-zA-Z_0-9]
NEWLINE [\r]?\n
%%

{WHITESPACE} {}

{NEWLINE} {lineCount++;}

"if"	{
	logOutput<<"Line# "<< lineCount <<": Token <IF> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"IF",lineCount,lineCount);
	return IF;
	}
"else"	{
	logOutput<<"Line# "<< lineCount <<": Token <ELSE> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"ELSE",lineCount,lineCount);
	return ELSE;
	}
"for"	{
	logOutput<<"Line# "<< lineCount <<": Token <FOR> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"FOR",lineCount,lineCount);
	return FOR;
	}
"while"	{
	logOutput<<"Line# "<< lineCount <<": Token <WHILE> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"WHILE",lineCount,lineCount);
	return WHILE;
	}
"do"	{
	logOutput<<"Line# "<< lineCount <<": Token <DO> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"DO",lineCount,lineCount);
	return DO;
	}
"break" {
	logOutput<<"Line# "<< lineCount <<": Token <BREAK> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"BREAK",lineCount,lineCount);
	return BREAK;
	}
"int"	{
	logOutput<<"Line# "<< lineCount <<": Token <INT> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"INT",lineCount,lineCount);
	return INT;
}
"char"	{
	logOutput<<"Line# "<< lineCount <<": Token <CHAR> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"CHAR",lineCount,lineCount);
	return CHAR;
}
"float"	{
	logOutput<<"Line# "<< lineCount <<": Token <FLOAT> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"FLOAT",lineCount,lineCount);
	return FLOAT;
} 
"double"	{
	logOutput<<"Line# "<< lineCount <<": Token <DOUBLE> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"DOUBLE",lineCount,lineCount);
	return DOUBLE;
}
"void"	{
	logOutput<<"Line# "<< lineCount <<": Token <VOID> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"VOID",lineCount,lineCount);
	return VOID;
}
"return"	{
	logOutput<<"Line# "<< lineCount <<": Token <RETURN> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"RETURN",lineCount,lineCount);
	return RETURN;
}
"switch"	{
	logOutput<<"Line# "<< lineCount <<": Token <SWITCH> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"SWITCH",lineCount,lineCount);
	return SWITCH;
}
"case"	{
	logOutput<<"Line# "<< lineCount <<": Token <CASE> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"CASE",lineCount,lineCount);
	return CASE;
}
"default"	{
	logOutput<<"Line# "<< lineCount <<": Token <DEFAULT> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"DEFAULT",lineCount,lineCount);
	return DEFAULT;
}
"continue"	{
	logOutput<<"Line# "<< lineCount <<": Token <CONTINUE> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"CONTINUE",lineCount,lineCount);
	return CONTINUE;
}
"println"	{
	logOutput<<"Line# "<< lineCount <<": Token <PRINTLN> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext,"PRINTLN",lineCount,lineCount);
	return PRINTLN;
}

{LETTER}{ALPHA_NUMERIC}*	{
	logOutput<<"Line# "<< lineCount <<": Token <ID> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext, "ID", lineCount, lineCount);
	return ID;
}

{DIGIT}+	{
	logOutput<<"Line# "<< lineCount <<": Token <CONST_INT> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext, "CONST_INT", lineCount, lineCount);
	return CONST_INT;
	// tokenOutput<<"<CONST_INT, "<<yytext<<">"<<endl;
	// logOutput<<"Line# "<<lineCount<<": Token <CONST_INT> Lexeme "<<yytext<<" found"<<endl;	
}

{DIGIT}*(\.{DIGIT}+)?([Ee][+-]?{DIGIT}+)?	{
	logOutput<<"Line# "<< lineCount <<": Token <CONST_FLOAT> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new SymbolInfo(yytext, "CONST_FLOAT", lineCount, lineCount);
	return CONST_FLOAT;
}

{DIGIT}*(\.{DIGIT}+)\.[0-9\.Ee+-]*(\.)* {
	errorCount++;
	logOutput<<"Error at line# "<< lineCount <<": TOO_MANY_DECIMAL_POINTS "<<yytext<<endl;
}

({DIGIT}*(\.{DIGIT}*)?[Ee][+-]?[0-9\.Ee+-]*(\.)*)|({DIGIT}+\.) {
	errorCount++;
	logOutput<<"Error at line# "<< lineCount <<": ILLFORMED_NUMBER "<<yytext<<endl;
}

{DIGIT}+{ALPHA_NUMERIC}+ {
	errorCount++;
	logOutput<<"Error at line# "<< lineCount <<": INVALID_ID_SUFFIX_NUM_PREFIX "<<yytext<<endl;
}

\/\/(([^\\\r\n]|\\[^\r\n])*(\\[\r]?\n)*)*	{
	string temp=yytext;
	int lineCountAdd=countNewLines(temp);
	if(temp[temp.length()-1]=='\n')temp=temp.substr(0,temp.length()-2);
	logOutput<<"Line# "<< lineCount <<": Token <SINGLE LINE COMMENT> Lexeme "<<temp<<" found"<<endl;
	lineCount+=lineCountAdd;
}

\/\* {
	comment=yytext;
	BEGIN MULTI_COMMENT_STATE;
}

"+"|"-"	{
	logOutput<<"Line# "<< lineCount <<": Token <ADDOP> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"ADDOP", lineCount, lineCount);
	return ADDOP;
}

"*"|"/"|"%"	{
	logOutput<<"Line# "<< lineCount <<": Token <MULOP> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"MULOP", lineCount, lineCount);
	return MULOP;
}

"++"	{
	logOutput<<"Line# "<< lineCount <<": Token <INCOP> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"INCOP", lineCount, lineCount);
	return INCOP;
}

"--"	{
	logOutput<<"Line# "<< lineCount <<": Token <DECOP> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"DECOP", lineCount, lineCount);
	return DECOP;
}

"<"|"<="|">"|">="|"=="|"!="	{
	logOutput<<"Line# "<< lineCount <<": Token <RELOP> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"RELOP", lineCount, lineCount);
	return RELOP;
}

"="	{
	logOutput<<"Line# "<< lineCount <<": Token <ASSIGNOP> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"ASSIGNOP", lineCount, lineCount);
	return ASSIGNOP;
}

"&&"|"||"	{
	logOutput<<"Line# "<< lineCount <<": Token <LOGICOP> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"LOGICOP", lineCount, lineCount);
	return LOGICOP;
}

"!"	{
	logOutput<<"Line# "<< lineCount <<": Token <NOT> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"NOT", lineCount, lineCount);
	return NOT;
}

"("	{
	logOutput<<"Line# "<< lineCount <<": Token <LPAREN> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"LPAREN", lineCount, lineCount);
	return LPAREN;
}

")"	{
	logOutput<<"Line# "<< lineCount <<": Token <RPAREN> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"RPAREN", lineCount, lineCount);
	return RPAREN;
}

"{"	{
	logOutput<<"Line# "<< lineCount <<": Token <LCURL> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"LCURL", lineCount, lineCount);
	return LCURL;
}

"}"	{
	logOutput<<"Line# "<< lineCount <<": Token <RCURL> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"RCURL", lineCount, lineCount);
	return RCURL;
}

"["	{
	logOutput<<"Line# "<< lineCount <<": Token <LSQUARE> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"LSQUARE", lineCount, lineCount);
	return LSQUARE;
}

"]"	{
	logOutput<<"Line# "<< lineCount <<": Token <RSQUARE> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"RSQUARE", lineCount, lineCount);
	return RSQUARE;
}

"," {
	logOutput<<"Line# "<< lineCount <<": Token <COMMA> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"COMMA", lineCount, lineCount);
	return COMMA;
}

";"	{
	logOutput<<"Line# "<< lineCount <<": Token <SEMICOLON> Lexeme "<<yytext<<" found"<<endl;
	yylval.symbolInfo = new  SymbolInfo(yytext,"SEMICOLON", lineCount, lineCount);
	return SEMICOLON;
}

'(\\[nt\\'afrbv0]|[^\\'])'	{
	string temp=getPrintableString(yytext);
	logOutput<<"Line# "<< lineCount <<": Token <CONST_CHAR> Lexeme "<<temp.substr(1,temp.length()-2)<<" found"<<endl;
}

'(\\[nt\\'afrbv0]|[^\\\n'])+'	{
	errorCount++;
	logOutput<<"Error at line# "<< lineCount <<": MULTICHAR_CONST_CHAR "<<yytext<<endl;
}

'\\'|'[^']	{
	errorCount++;
	string temp=yytext;
	int addLineCount=0;
	if(temp[temp.length()-1]=='\n'){
		addLineCount=1;
		temp=temp.substr(0,temp.length()-1);
	}
	logOutput<<"Error at line# "<< lineCount <<": UNFINISHED_CONST_CHAR "<<temp<<endl;
	lineCount+=addLineCount;
}


''	{
	errorCount++;
	logOutput<<"Error at line# "<< lineCount <<": EMPTY_CONST_CHAR "<<yytext<<endl;
}

\"([^\"\\\n]|\\[nt\\\"\'afrbv0])*\"	{
	string temp=yytext;
	temp=getPrintableString(temp.substr(1,temp.length()-2));
	logOutput<<"Line# "<< lineCount <<": Token <SINGLE LINE STRING> Lexeme "<<yytext<<" found"<<endl;
}

\"(([^\"\\\r\n]|\\[nt\\\"\'afrbv0])*(\\[\r]?\n)*)*\"	{
	string temp=yytext;
	temp=getPrintableString(temp.substr(1,temp.length()-2));
	logOutput<<"Line# "<< lineCount <<": Token <MULTI LINE STRING> Lexeme "<<yytext<<" found"<<endl;
	lineCount+=countNewLines(yytext);
}

\"(([^\"\\\r\n]|\\[nt\\'afrbv0])*(\\[\r]?\n)*)*	{
	errorCount++;
	string temp=yytext;
	if(temp[temp.length()-1]=='\n')temp.pop_back();
	lineCount+=countNewLines(temp);
	//just to count the newlines in the string
	logOutput<<"Error at line# "<< lineCount <<": UNFINISHED_STRING "<<yytext<<endl;
}

<MULTI_COMMENT_STATE>\*\/	{
	comment+="*/";
	logOutput<<"Line# "<< lineCount-countNewLines(comment) <<": Token <MULTI LINE COMMENT> Lexeme "<<comment<<" found"<<endl;
	BEGIN INITIAL;
	}
<MULTI_COMMENT_STATE>\n	{
	comment+='\n';
	lineCount++;
}
<MULTI_COMMENT_STATE><<EOF>>	{
	errorCount++;
	logOutput<<"Error at line# "<< lineCount <<": UNFINISHED_COMMENT "<<comment<<endl;
	BEGIN INITIAL;
}
<MULTI_COMMENT_STATE>.	{
	comment+=yytext;
}

. {
	errorCount++;
	logOutput<<"Error at line# "<< lineCount <<": UNRECOGNIZED_CHAR "<<yytext<<endl;
}

%%
