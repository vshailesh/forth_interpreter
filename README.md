# ForthInterpreter

An interpreter implementation of the Stack Based Programming Language named Forth [Documentation](https://www.forth.com/forth/)

This is an interpreter and not a compiler. Please follow along the steps to run it on your machine and evaluate some expressions.

## Step to run the Interpreter
### Clone the Repo
```git
git clone https://github.com/vshailesh/forth_interpreter
```

```
cd ~/<path_to_repo_folder>/forth_interpreter
```

### Run Tests
All tests must pass
```
mix test
```

### Start the Repl
To start the `repl` interface run the following make command
```
make repl
```

### Evaluate Forth Expression 
```
Forth.Forth.eval("1 2 +")

Forth.Forth.eval("1 2 + 3 * 4 -")

Forth.Forth.eval("1 2 dup")
```

## Architecture 
The implementation is divided in 2 parts

### Parser
First part is the parser which parses the input expression and generates an Abstract Syntax Tree (AST). This is implemented using the Nimble Parsec, a parser combinator library in Elixir.

### Executor
Once we have an Abstract Syntax Tree(AST) of our expression, it is passed through appropriate executor function. Each executor function is different and evaluates one type of expression.

### Error Handling and Reporting
Error are handled and reported on different levels, for example the basic error handling implementation for catching invalid word definition declaration is done during the Parsing stage.

Whereas lets say you called a `word` (or function as it is called in other languages), this is reported from the executor stage, where it is checked if the function is actually defined somewhere or not.
Or the dividing by zero in an arithmetic operation, this is also reported from the executor stage.

Error reporting is very minimal right now.