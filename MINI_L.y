/* Student Name: Aaron Sanders
*/ 
%{
 #include <sstream>
 #include <map>
 #include <iterator>
 #include <fstream>
 #include <string>
 #include <iostream>
 #include <unistd.h>
 #include <stdio.h>
 #include <math.h>
 #include <stdlib.h>
 #include <string.h>
 #include <stdio.h>
 #include "y.tab.h" 
 #include <list>
 #include <vector>

 using namespace std;

 int productionID = 0;
 int myError;
 int yylex (void);
 void yyerror (char const *);
 extern int currLine;
 extern int colPos;
 extern int ident_count;
 int numToken;
 char* identToken;
 char* filename;
 string program_name;
 string mil_file_name;
 char* array_int;
 bool dont_print = false;
 int predCounter = 0;//predicate variable counter
 int tempCounter = 0;//temp variable counter
 int labelCounter = 0;

 char* string_to_char_star(string entry, char* &temp){  //converting string to char* - put into function
	
	copy(entry.begin(), entry.end(), temp);
	temp[entry.size()] = '\0';
	return temp;
									 
 };

 list<string> label_table; //list of labels
 list<string> symbol_table_local; //local variable symbol table - predicate and temporary variables
 list<string> symbol_table; //symbol table (vector) -> change to stack or queue later (for scope)  <- HERE
 map<string, string> symbol_table2; //symbol table with array/integer tag


 list<string>::iterator var_pointer = symbol_table.begin();

 bool in_loop = false;

 string pred_var;
 string temp_var;

 struct StringListNode{
	char value[254];
	struct StringListNode *newNode;
 };

void popInstrField(struct StringListNode &newNode, int instrType, char *op1, char *op2, char *op3){ //function hold the pieces for the mil code
	switch(instrType){
		case 1: { //. _name  . _op1 -- VARIABLE DECLARATION
			sprintf(newNode.value, "  . %s\n", op1);
			break;
		}
		case 2: { // .[] _name, n  .[] _op1, op2-- ARRAY DECLARATION
			sprintf(newNode.value, "  .[] %s, %s\n", op1, op2);
			break;			
		}
		case 3: { // : label  : op1 (L1, L2, ...)  -- LABEL
			sprintf(newNode.value, ": %s\n", op1);
			break;	
		}
		case 4: { // =[] dst, src1, index  dst = src1[index]  =[] op1, op2, op3 -- ASSIGNMENT FROM ARRAY
			sprintf(newNode.value, "  =[] %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 5: { // * dst, src1, src2  dst = src1 * src2  * op1, op2, op3 -- MULTIPLICATION
			sprintf(newNode.value, "  * %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 6: { // / dst, src1, src2  dst = src1 / src2  / op1, op2, op3 -- DIVISION
			sprintf(newNode.value, "  / %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 7: { // - dst, src1, src2  dst = src1 - src2  - op1, op2, op3 -- SUBTRACT
			sprintf(newNode.value, "  - %s, %s, %s\n", op1, op2, op3);
		}
		case 8: { // + dst, src1, src2  dst = src1 + src2  + op1, op2, op3 -- ADDITION
			sprintf(newNode.value, "  + %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 9: { // % dst, src1, src2  dst = src1 % src2  % op1, op2, op3 -- MODULUS
			sprintf(newNode.value, "  % %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 10: { // == dst, src1, src2  dst = src1 == src2  == op1, op2, op3 -- EQUALITY
			sprintf(newNode.value, "  == %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 11: { // != dst, src1, src2  dst = src1 != src  != op1, op2, op3 --NOT EQUALITY
			sprintf(newNode.value, "  != %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 12: { // < dst, src1, src2  dst = src1 < src2  < op1, op2, op3 -- LESS THAN
			sprintf(newNode.value, "  < %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 13: { // > dst, src1, src2  dst = src1 > src2  > op1, op2, op3 -- GREATER THAN
			sprintf(newNode.value, "  > %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 14: { // <= dst, src1, src2  dst = src1 <= src2  <= op1, op2, op3 -- LTE
			sprintf(newNode.value, "  <= %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 15: { // >= dst, src1, src2  dst = src1 >= src2  >= op1, op2, op3 -- GTE
			sprintf(newNode.value, "  >= %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 16: { // ! dst, src  dst = !src  ! op1, op2 -- logical NOT 
			sprintf(newNode.value, "  ! %s, %s\n", op1, op2);
			break;
		}
		case 17: { // && dst, src1, src2  dst = src1 && src2  && op1, op2, op3 -- && (logical AND)
			sprintf(newNode.value, "  && %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 18: { // || dst, src1, src2  dst = src1 || src2  || op1, op2, op3 -- || (logical OR)
			sprintf(newNode.value, "  || %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 19: { // .[]< dst, index  .[]< op1, op2 -- READ ARRAY  (from standard input)
			sprintf(newNode.value, "  .[]< %s, %s\n", op1, op2);
			break;
		}
		case 20: { // .< dst  .< op1 -- READ VARIABLE  (from standard input)
			sprintf(newNode.value, "  .< %s\n", op1);
			break;
		}
		case 21: { // .[]> src, index  .[]> op1, op2 -- WRITE ARRAY  (to standard output)
			sprintf(newNode.value, "  .[]> %s, %s\n", op1, op2);
			break;
		}
		case 22: { // .> src  .> op1 -- WRITE VARIABLE  (to standard output)
			sprintf(newNode.value, "  .> %s\n", op1);
			break;
		}
		case 23: { // []= dst, index, src  dst[index] = src  []= op1, op2, op3 -- ASSIGN TO ARRAY
			sprintf(newNode.value, "  []= %s, %s, %s\n", op1, op2, op3);
			break;
		}
		case 24: { // ?:= label, predicate  if predicate is true (1) goto label  ?:= op1, op2 -- CONDITIONAL BRANCH
			sprintf(newNode.value, "  ?:= %s, %s\n", op1, op2);
			break;
		}
		case 25: { // := label  goto label  := op1 -- GOTO
			sprintf(newNode.value, "  := %s\n", op1);
			break;
		}
		case 26: { // = dst, src  dst = src  = op1, op2 -- ASSIGN
			sprintf(newNode.value, "  = %s, %s\n", op1, op2);
			break;
		}
	}
 };


 vector<string> generated_mil; //holds the mil_code which will be output after yyparse() returns
 vector<string> error_stream; //hold the error messags accumulated through the program --  will output instead of mil_code if errors found

 

 void update_mil_code(string var){//update mil_code
	struct StringListNode x;
 	char* temp = new char[var.size()-1];
	char* temp2 = string_to_char_star(var, temp);
	popInstrField(x, 1, temp2, "", "");
	for(vector<string>::iterator it = generated_mil.begin(); it != generated_mil.end(); ++it){
		if(*it == ": START\n"){
			generated_mil.insert(it, x.value);
			break;	
		} 
	}	
 };

 int string_to_int(string x){ //convert a string to int
	istringstream ss(x);
	int integ;
	ss >> integ;
	return integ;	
 };

 void create_pred_var() { //create predicate values
	char* temp = new char[25];
	sprintf(temp, "p%d", predCounter++);
	symbol_table_local.push_back(temp);
	pred_var = temp;
 };

 void create_temp_var() { //create temporary values
	char* temp = new char[25];
	sprintf(temp, "t%d", tempCounter++);
	symbol_table_local.push_back(temp);
	temp_var = temp;

 };

 void create_label() {
	char* temp = new char[25];
	sprintf(temp, "L%d", labelCounter++);
	struct StringListNode x;
	popInstrField(x, 3, temp, "", "");
	generated_mil.push_back(x.value);

 };

 bool entry_here(string ent, list<string> table){
	for(list<string>::iterator it = table.begin(); it != table.end(); ++it ){
		if((*it) == ent)
			return true;
	}
	return false;
 };

 void print_symbol_table(list<string> x){
	for(list<string>::iterator it = x.begin(); it != x.end(); ++it ){
		cout << *it << endl;
	}
 };

 string get_symbol_entry(char* token) { //gives variable names from the declaration stage, to be used to create the mil_code -- also for immediates
	string temp;
	for(unsigned i = 0; i < strlen(token); ++i) { 
		if(token[i] == ' ' || token[i] == ',' ||  token[i] == ';' || token[i] == ')' || token[i] == ':' || token[i] == '+' || token[i] == '-' || token[i] == '/')//LOOK AT THIS CODE FOR MULTIPLE ARRAY DECLARATIONS
			break;
                if(token[i] == '\n' || token[i] == '(')
			continue;
		
		temp += token[i];
	}
	return temp;
 };	

 char* get_expression(char* exp){
	string out_s;
	for(unsigned i = 0; i < strlen(exp); ++i){
		if(exp[i] == '(')
			continue;
		
		if(exp[i] == ')' || exp[i] == ';')
			break;
		
		out_s += exp[i];
	}
	
	char* temp = new char[out_s.size()-1];
	return string_to_char_star(out_s, temp);
	
 };


 char* get_mult(char* mult){
	string cow = mult;
	string rhs;
	for(unsigned i = 0; i < strlen(mult); ++i){
		if(mult[i] == ' ' || mult[i] == '\0' || mult[i] == ')' || mult[i] == ';'){
			continue;
		}
		if(i != 0 && (mult[i] == '/' || mult[i] == '*' || mult[i] == '%' || cow.substr(i, cow.size()-1) == "beginloop" || cow.substr(i, cow.size()-1) == "then")){
			break;
		}
		rhs += mult[i];
	}
	char* temp = new char[rhs.size()-1];
	return string_to_char_star(rhs, temp);
	
 };

 char* get_rel(char* piece){
	string cow = piece;
	string rhs;
	for(unsigned i = 0; i < strlen(piece); ++i){
		if(piece[i] == ' ' || piece[i] == '\0' || piece[i] == ')' || piece[i] == ';'){
			
			continue;
		}
		if(i != 0 && (cow.substr(i, cow.size()-1) == "beginloop" || cow.substr(i, cow.size()-1) == "then")){
			break;
		}
		rhs += piece[i];
		
		
	}
	char* temp = new char[rhs.size()-1];
	return string_to_char_star(rhs, temp);

 };

 char* get_arth(char* art){
	string cow = art;
	string rhs;
	for(unsigned i = 0; i < strlen(art); ++i){
		if(art[i] == ' ' || art[i] == '\0' || art[i] == ')' || art[i] == ';'){
			
			continue;
		}
		if(i != 0 && (art[i] == '+' || art[i] == '-' || cow.substr(i, cow.size()-1) == "beginloop" || cow.substr(i, cow.size()-1) == "then")){
			break;
		}
		rhs += art[i];
		
		
	}
	char* temp = new char[rhs.size()-1];
	return string_to_char_star(rhs, temp);
 };


 
%}

%union{
   char* word;
   double dval;
   int	ival;
}

%start	program_start
%token<word> PROGRAM BEGIN_PROGRAM END_PROGRAM INTEGER ARRAY OF IF THEN ENDIF ELSE WHILE DO BEGINLOOP ENDLOOP CONTINUE READ WRITE AND OR NOT TRUE FALSE
%left<word> ADD SUB
%left<word> MULT DIV
%left<word> MOD
%token<word> EQ NEQ LT GT LTE GTE SEMICOLON COLON COMMA L_PAREN R_PAREN ASSIGN 
%token<word> IDENT
%token<dval> NUMBER
%type<word> program_start block block2 block3 declaration declaration2 declaration3 statement statement2 statement3 bool_exp bool_exp2 relation_and_expression relation_and_expression2 relation_exp relation_exp2 comp expression expression2 multiplicative_exp multiplicative_exp2 term term2 var var2
%type<word> program begin_program ident then end_program integer array of if endif else while do beginloop endloop continue read write and or not true false
%type<word> add sub mult div mod eq neq lt gt lte gte semicolon colon comma l_paren r_paren assign
%type<word> number 

%%
semicolon:	SEMICOLON { if(yychar == YYEOF){yyerror("missing 'endprogram'");}}
		| error {yyerror(" missing ';' ");};

begin_program:	BEGIN_PROGRAM {$$ = yylval.word; 	
				struct StringListNode y;	
				popInstrField(y, 3, "START", "", "");	
				generated_mil.push_back(y.value);
			      } /* fix this syntax error later */
		| error {yyerrok; yyerror("missing 'beginprogram'");};

add:	ADD {$$ = yylval.word; }
	| error {yyerror(" '+' expected ");};

sub:	SUB {$$ = yylval.word; }
	| error {yyerror(" '-' expected ");};

mult:	MULT {$$ = yylval.word; }
	| error {yyerror(" '*' expected ");};

div:	DIV {$$ = yylval.word; }
	| error {yyerror(" '/' expected");};

mod:	MOD {$$ = yylval.word; }
	| error {yyerror(" expected '%' ");};

eq:	EQ {$$ = yylval.word; }
	;/* error {yyerror(" invalid comparator ");};*/

neq:	NEQ {$$ = yylval.word; }
	;/* error {yyerror(" invalid comparator ");};*/

lt:	LT {$$ = yylval.word; }
	;/* error {yyerror(" invalid comparator ");};*/

gt:	GT { $$ = yylval.word; }
	;/* error {yyerror(" invalid comparator ");};*/

lte:	LTE {$$ = yylval.word; }
	;/* error {yyerror(" invalid comparator ");};*/

gte:	GTE {$$ = yylval.word; }
	;/* error {yyerror(" invalid comparator ");};*/

colon:	COLON {$$ = yylval.word; }
	| error {yyerror(" invalid declaration ");};

comma:	COMMA {$$ = yylval.word; }
	| error {yyerror(" expected ',' ");};

l_paren:	L_PAREN {$$ = yylval.word; }
		| error {yyerror(" missing '(' ");};

r_paren:	R_PAREN {$$ = yylval.word; }
		| error {yyerror(" missing ')' ");};

assign:		ASSIGN {$$ = yylval.word; }
		| error {yyerror(" ':=' expected ");};

program: 	PROGRAM { }
		| error {yyerror("Error in program");};

ident: 		IDENT {$$ = identToken; if(ident_count == 1){ //creating of the XXXX.mil file
						filename = $$;
						string x = filename;
						program_name = x;
						x += ".mil";
						mil_file_name = x;
						ofstream mil_file(x.c_str());
						mil_file.close();
					}
						
		}
		| error {yyerror(" missing identifier ");};

number:		NUMBER { 
			 stringstream ss; ss << numToken; 
			 string cash; ss >> cash; 
			 char* temp = new char[cash.size()-1]; 
			 $$ = string_to_char_star(cash, temp);

		       } /* make numTok an int, later  */
		| error {yyerror(" invalid value for 'number' ");};

array:		ARRAY {$$ = yylval.word;}
		| error {yyerror(" 'array' expected ");};

of:		OF {$$ = yylval.word; }
		| error {yyerror(" 'of' expected ");};

if:		IF {$$ = yylval.word; }
		| error {if(yychar == YYEOF){yyerror(" missing 'endprogram'");} else {yyerror(" 'if' expected ");}};

endif:		ENDIF {$$ = yylval.word; }
		| error {yyerror(" 'endif' expected ");};
		
else:		ELSE {$$ = yylval.word; }
		| error {yyerror(" 'else' expected ");};

while:		WHILE {$$ = yylval.word; }
		| error {if(yychar == YYEOF){yyerror(" missing 'endprogram'");} else {yyerror(" 'while' expected ");}};

do:		DO {$$ = yylval.word; }
		| error {if(yychar == YYEOF){yyerror(" missing 'endprogram'");} else {yyerror(" 'do' expected ");}};

beginloop:	BEGINLOOP {$$ = yylval.word; }
		| error {yyerror(" 'beginloop' expected ");};

endloop:	ENDLOOP	{$$ = yylval.word; in_loop = false; }
		| error {yyerror(" 'endloop' expected ");};

continue:	CONTINUE {$$ = yylval.word; if(!in_loop)
						yyerror("cannot call 'continue' outside of a loop");
			 }
		| error {yyerror(" 'continue' expected");};

read:		READ {$$ = yylval.word; }
		| error {yyerror(" 'read' expected");};

write:		WRITE {$$ = yylval.word; }
		| error {yyerror(" 'write' expected");};

and:		AND {$$ = yylval.word; }
		| error {yyerror(" 'and' expected ");};

then:		THEN {$$ = yylval.word; }
		| error {yyerror(" 'then' expected ");};

or:		OR {$$ = yylval.word; }
		|  error {yyerror(" 'or' expected ");};

not:		NOT {$$ = yylval.word; }
		| error {yyerror(" expected 'not' ");};

true:		TRUE {$$ = yylval.word; }
		| error {yyerror("expected 'true'");};

false:		FALSE {$$ = yylval.word; }
		| error {yyerror("expected 'false'");};

integer:	INTEGER {$$ = yylval.word;}
		| error {yyerror(" expecting 'integer'");};

end_program:	END_PROGRAM { }
	 	| error {yyerrok; yyerror(" 'endprogram' expected");};

program_start: 	program ident semicolon block end_program { };

block:		declaration block2 begin_program statement semicolon block3 { }; /*use trick for beginprogram and endprogram*/
		
block2:		
		/* empty */	{ } 	
		| declaration block2	{ };

block3: 	
		/* empty */	{ }
		| statement semicolon block3 { };

declaration:	ident declaration2 colon declaration3 integer semicolon { string entry = get_symbol_entry($1); //gets variable names from declaration statement

									  if(!entry_here(entry, symbol_table)){//ERROR 2a. checking that variable not declared more than once
										if(entry == "program" || entry == "beginprogram" || entry == "endprogram" || entry == "integer" || entry == "array" || entry == "of" || entry == "if" || entry == "then" || entry == "endif" || entry == "else" || entry == "while" || entry == "do" || entry == "beginloop" || entry == "endloop" || entry == "continue" || entry == "read" || entry == "write" || entry == "and" || entry == "or" || entry == "not" || entry == "true" || entry == "false"){
										yyerror("variable name is a reserved word");//ERROR 3. variable name cant be reserved word
									  	}else{
										    symbol_table.push_back(entry);
										}
									  }else{
										yyerror("cannot define variable more than once");
									  }

									  char* temp = new char[entry.size() - 1]; //converting string to char* - put into function
									
									  char* temp2 = string_to_char_star(entry, temp);
						
									  if(entry == program_name)// ERROR 2b. checking that variable name not same as program name. Print error message
									  	yyerror("cannot name variable same as program name");
									
									  struct StringListNode x;

									  string array_tag = $4; 

									  if(array_tag == "array"){//selects correct variable declaration mil output
										symbol_table2[temp2] = "array";
									  	popInstrField(x, 2, temp2, array_int, ""); //selecting corresponding mil code -- array variable
									  }else{
										symbol_table2[temp2] = "integer";
										popInstrField(x, 1, temp2, "", "");//integer variable	
									  }
									  delete [] temp;
									   
									  generated_mil.push_back(x.value); //pushing mil code into post-program output vector
									 };

declaration2:	
		/* empty */	{$$ = ""; }
		| comma ident declaration2 { string entry = get_symbol_entry($2);//same comments as for 'declaration' production
					     if(!entry_here(entry, symbol_table)){//ERROR 2a. checking that variable not declared more than once
						 if(entry == "program" || entry == "beginprogram" || entry == "endprogram" || entry == "integer" || entry == "array" || entry == "of" || entry == "if" || entry == "then" || entry == "endif" || entry == "else" || entry == "while" || entry == "do" || entry == "beginloop" || entry == "endloop" || entry == "continue" || entry == "read" || entry == "write" || entry == "and" || entry == "or" || entry == "not" || entry == "true" || entry == "false"){
						     yyerror("variable name is a reserved word");
						 }else{
							symbol_table.push_back(entry);
						 }
					     }else{
						yyerror("cannot define variable more than once");
					     }
					     char* temp = new char[entry.size() - 1];

					     char* temp2 = string_to_char_star(entry, temp);
					     if(entry == program_name)		
						   yyerror("cannot name variable same as program name");
					     
					     struct StringListNode x;
					     symbol_table2[temp2] = "integer";
					     popInstrField(x, 1, temp2, "", "");
					     delete [] temp;
	
					     generated_mil.push_back(x.value);
		};
declaration3:
		/* empty */	{$$=""; }
		| array l_paren number r_paren of {string x = get_symbol_entry($3); 
						   if(atoi($3) <= 0){//ERROR 6. declare an array of size <= 0
							yyerror("cannot declare an array of size 0 or less");
						   }
						   char* temp = new char[x.size()-1]; 
						   array_int = string_to_char_star(x, temp);  };

statement:	var assign expression	{ char* lhs = $1;
					  char* rhs = $3; 
					  struct StringListNode x;
					  popInstrField(x, 26, lhs, rhs, "");
					  generated_mil.push_back(x.value);
					}
		| if bool_exp then statement semicolon statement2 endif	{   	



									 }
		| if bool_exp then statement semicolon statement2 else statement2 endif { }
		| while bool_exp beginloop statement semicolon statement2 endloop	{in_loop = true;


											 }
		| do beginloop statement semicolon statement2 endloop while bool_exp	{in_loop = true;
	
						
											 }
		| read var statement3	{string ent = get_symbol_entry($2);
					 char* temp = new char[ent.size() - 1];
					 char* temp2 = string_to_char_star(ent, temp);
					 
					 struct StringListNode x;
				         if(symbol_table2[temp2] == "integer"){//add array read later <- HERE
						popInstrField(x, 20, temp2, "", "");
					 }
					 delete [] temp;
					 generated_mil.push_back(x.value);

					 }
		| write var statement3	{
					 string ent = get_symbol_entry($2);
					 char* temp = new char[ent.size() - 1];
					 char* temp2 = string_to_char_star(ent, temp);
					 
					 struct StringListNode x;
				         if(symbol_table2[temp2] == "integer"){//add array read later <- HERE
						popInstrField(x, 22, temp2, "", "");
					 }
					 delete [] temp;
					 generated_mil.push_back(x.value);

					 }
		| continue	{ };

statement2:
		/* empty */	{$$ = ""; }
		| statement semicolon statement2 	{


							};

statement3:
		/* empty */	{$$ = "" }
		| comma var statement3	{


					};

bool_exp:	relation_and_expression bool_exp2	{								

							};

bool_exp2:
		/* empty */   	{$$ = ""; }
		| or relation_and_expression bool_exp2 {char* so = $2;
			
					 		create_temp_var();
				        	 	update_mil_code(temp_var);
				
					 		char* temp3 = new char[20];//predicate variable
				  	 		char* temp4 = string_to_char_star(symbol_table_local.back(), temp3);	
							
					 		struct StringListNode x;
					 		popInstrField(x, 18, temp4, so, "");
					 		generated_mil.push_back(x.value);
							
							$$ = temp4;

							};

relation_and_expression:	relation_exp relation_and_expression2	{$$ = $2;
										
								 	};

relation_and_expression2:	
		/* empty */	{$$ = ""; }
		| and relation_exp relation_and_expression2 	{char* go = $2; 
		 			
							  	 create_temp_var();
				        			 update_mil_code(temp_var);
				
					 			 char* temp3 = new char[20];//predicate variable
				  	 			 char* temp4 = string_to_char_star(symbol_table_local.back(), temp3);	
							
					 			 struct StringListNode x;
					 			 popInstrField(x, 17, temp4, go, "");
					 			 generated_mil.push_back(x.value);

								 $$ = temp4;
								 };

relation_exp: 	not relation_exp2	{char* no = $2;
					
					 create_temp_var();
				         update_mil_code(temp_var);
				
					 char* temp3 = new char[20];//predicate variable
				  	 char* temp4 = string_to_char_star(symbol_table_local.back(), temp3);	
							
					 struct StringListNode x;
					 popInstrField(x, 16, temp4, no, "");
					 generated_mil.push_back(x.value);

				 	$$ = temp4;

					 }
		| relation_exp2		{$$ = $1; };

relation_exp2:	expression comp expression	{char* lhs = $1;
						 char* rhs = get_rel($2);
						 string orig = rhs;
						 string comp;
						 string newt;
						 for(unsigned i = 0; i < strlen(rhs); i++){
							if(rhs[i] == '>' || rhs[i] == '=' || rhs[i] == '<' || rhs[i] == '!'){
								comp += rhs[i];
								continue;
							}
							if(rhs[i] == '/' || rhs[i] == '*' || rhs[i] == '%'){
								break;
							}
							newt += rhs[i];
						 }
						 
						if(strcmp(orig.c_str(), newt.c_str()) != 0){
							create_temp_var();
							update_mil_code(temp_var);
						
		 					 char* temp = new char[newt.size() - 1];
					 		 char* temp2 = string_to_char_star(newt, temp);
					
							 
			
							 char* temp3 = new char[20];//predicate variable
							 char* temp4 = string_to_char_star(symbol_table_local.back(), temp3);	
		
							
							 struct StringListNode x;
						  
							 if(comp == "=="){
								popInstrField(x, 10, temp4, lhs, temp2);
							 }else if(comp == "<"){
								popInstrField(x, 12, temp4, lhs, temp2);

							 }else if(comp == ">"){
								popInstrField(x, 13, temp4, lhs, temp2);
	
							 }else if(comp == "!="){
								popInstrField(x, 11, temp4, lhs, temp2);
		
							 }else if(comp == "<="){
								popInstrField(x, 14, temp4, lhs, temp2);

							 }else if(comp == ">="){
								popInstrField(x, 15, temp4, lhs, temp2);
							 }	   	 

							$$ = temp4;

							 generated_mil.push_back(x.value);
						}
					}//do work here - declare temporary variables
		| true		{$$ = $1; }
		| false		{$$ = $1; }
		| l_paren bool_exp r_paren	{ };

comp:		eq	{string x = $1; $$ = $1; } 
		| neq	{string x = $1; $$ = $1; }
		| lt	{string x = $1; $$ = $1; }
		| gt	{string x = $1; $$ = $1; }
		| lte	{string x = $1; $$ = $1; }
		| gte	{string x = $1; $$ = $1; }
		| error {yyerror("invalid comparator");};
		

expression:	multiplicative_exp expression2	{ char* lhs = $1;
						  char* rhs = $2; 
							string orig = lhs;	
							string newt;
							char sign;	
							for(unsigned i = 0; i < strlen(lhs); ++i){
								if(lhs[i] == ' '){
									continue;	
								}
								if(lhs[i] == '+' || lhs[i] == '-'){
									break;	
								}
								
			
								newt += lhs[i];
							}
							string newt2;
							
							for(unsigned i = 0; i < strlen(rhs); ++i){
								if(rhs[i] == '+' || rhs[i] == '-'){
									sign = rhs[i];
									continue;
								}
								if(rhs[i] == ' ' || rhs[i] == '\0'){
									break;
								}
								
								
								newt2 += rhs[i];
							}
						
							if(strcmp(orig.c_str(), newt.c_str()) != 0){
								create_pred_var();
								update_mil_code(pred_var);
							
								char* temp = new char[newt.size() - 1];//lhs
						 	 	char* temp2 = string_to_char_star(newt, temp);

								char* temp_b = new char[200];
								
								if(newt2.size() > 0){	
									char* k = new char[newt2.size() - 1];//rhs
									temp_b = string_to_char_star(newt2, k);
								}else{
									temp_b = "";
								}
								

								char* temp3 = new char[20];//predicate variable
								char* temp4 = string_to_char_star(symbol_table_local.back(), temp3);
							
						 		struct StringListNode x;

								if(sign == '+'){
									popInstrField(x,8, temp4, temp2, temp_b);
								} else if (sign == '-'){
									popInstrField(x,7, temp4, temp2, temp_b);
								}	

								generated_mil.push_back(x.value);
							
								$$ = temp4;

							}	
						};
	
expression2: 	
		/* empty */	{$$ = ""; }
		| add multiplicative_exp expression2	{
								$$ = get_arth($1); cout << $$ << endl;
							}
		| sub multiplicative_exp expression2	{
								$$ = get_arth($1);
							}
		| error {yyerror("invalid expression");};

multiplicative_exp:	term multiplicative_exp2	{char* lhs = $1;
							 char* rhs = $2;
							string orig = lhs;	
							string newt;
							char sign;	
							for(unsigned i = 0; i < strlen(lhs); ++i){
								if(lhs[i] == ' ' || lhs[i] == '+' || lhs[i] == '-'){
									continue;	
								}
		
								if((i + 1) < strlen(lhs)){
									if((lhs[i+1] == '+' || lhs[i+1] == '-'))
										continue;
								}
		
								if(lhs[i] == '/' || lhs[i] == '*' || lhs[i] == '%'){
									break;	
								}
								
			
								newt += lhs[i];
							}
							string newt2;
							cout << newt << endl;	
							for(unsigned i = 0; i < strlen(rhs); ++i){
								if(rhs[i] == '/' || rhs[i] == '*' || rhs[i] == '%'){
									sign = rhs[i];
									continue;
								}
								if(rhs[i] == '\0' || rhs[i] == ' '){
									break;
								}
								
								newt2 += rhs[i];
							}
													
							if(strcmp(orig.c_str(), newt.c_str()) != 0){
								create_pred_var();
								update_mil_code(pred_var);
								

								char* temp = new char[newt.size() - 1];//lhs
						 	 	char* temp2 = string_to_char_star(newt, temp);
							
								char* k = new char[newt2.size() - 1];//rhs
								char* temp_b = string_to_char_star(newt2, k);
		
								char* temp3 = new char[20];//predicate variable
								char* temp4 = string_to_char_star(symbol_table_local.back(), temp3);
								
							 	struct StringListNode x;
	
								if(sign == '/'){
									popInstrField(x,6, temp4, temp2, temp_b);
								} else if (sign == '*'){
									popInstrField(x,5, temp4, temp2, temp_b);
								} else if (sign == '%'){
									popInstrField(x,9, temp4, temp2, temp_b);
								}						
	
								generated_mil.push_back(x.value);
								
								$$ = temp4;
			
							}
						};

multiplicative_exp2:	
			/* empty */	{$$ = ""; }
			| mod term multiplicative_exp2	{$$ = get_mult($1); }
			| mult term multiplicative_exp2	{$$ = get_mult($1); }
			| div term multiplicative_exp2	{$$ = get_mult($1); };

term: 		sub term2	{$$ = get_expression($1); }
		| term2		{$$ = get_expression($1); };

term2: 	
		var		{$$ = $1; }
		| number	{string x = get_symbol_entry($1);
				 char* temp = new char[x.size()-1]; 
				 $$ = string_to_char_star(x, temp);
				  
				}//convert $1 to char*
		| l_paren expression r_paren	{
							$$ = get_expression($1);
							
						 };

var:		ident var2	{
	
				
					string holder_check = $1;

					unsigned x = 0;//checking to see where '(' is in a 'array(var)' case
					while(x < holder_check.size()){
						if(holder_check[x] == '(')
							break;
						++x;
					}

					unsigned y = 0;//checking to see where ')' is in a 'array(var) case
					while(y < holder_check.size()){
						if(holder_check[y] == ')')
							break;
						++y;
					}
                                        
					string::iterator it = holder_check.end();

					string temp;
					
					if($2 != "" && holder_check[x] == '('){
						char* temp2 = new char[holder_check.size()-1];//parse array variable name
						temp = holder_check;
						temp.erase(x, temp.size()-1);
						char* temp3 = string_to_char_star(temp,temp2);			
						temp = get_symbol_entry(temp3);
						delete [] temp2;						
						if(!entry_here(temp, symbol_table)){//checking for use of undeclared variables
							yyerror("used variable is undeclared");
						}		
                                                char* back = new char[temp.size()-1];
						char* back2 = string_to_char_star(temp, back);
						$$ = back2; 
					}else if(holder_check[y] == *it){
						temp = get_symbol_entry($1);
						char* temp2 = new char[temp.size()-1];
						if(!entry_here(temp, symbol_table)){//checking for use of undeclared variables
							yyerror("used variable is undeclared");
						}
						char* back = new char[temp.size()-1];
						char* back2 = string_to_char_star(temp, back);
						$$ = back2; 
					}
			};

var2:		
		/* empty */	{$$ = ""; }
		| l_paren expression r_paren	{
						string holder = $1;	
						char* holder_char = new char[holder.size()-1];//parse array index variable
						char* holder_2 = string_to_char_star(holder, holder_char);
						holder = get_symbol_entry(holder_2);
						delete [] holder_char;
						if(!entry_here(holder, symbol_table)){//checking for use of undeclared variables
							yyerror("used variable is undeclared");
						}
						
						
						char* temp2 = new char[holder.size()-1];
						char* temp3 = string_to_char_star(holder, temp2);
						$$ = temp3;	
							
				
						};//push through 'expression', ignoring parens
%%

int main(int argc, char **argv) {
  
   yyparse();

   
   if(!dont_print){
   	ofstream mil_file;
   	mil_file.open(mil_file_name.c_str());

   	for(unsigned i = 0; i < generated_mil.size(); i++){
		mil_file << generated_mil[i];
   	}

   	mil_file.close();
   }

   return 0;
}

void yyerror(const char *msg) {
   char* s;
   printf("**At line %d: %s\n", currLine, msg);
   dont_print = true;
}
