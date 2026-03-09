import org.antlr.v4.runtime.*;

public class Main {
    public static void main(String[] args) throws Exception {
        CharStream stream = CharStreams.fromFileName("grammars/stdin.c");
        CLexer lexer = new CLexer(stream);
        Token token;
        while ((token = lexer.nextToken()).getType() != Token.EOF) {
    if (token.getChannel() == Token.DEFAULT_CHANNEL) {
        System.out.printf("{\"token\": \"%s\", \"lexeme\": \"%s\"}\n",
            lexer.getVocabulary().getSymbolicName(token.getType()),
            token.getText());
    }
}
    }
}