#import "PKSParser.h"
enum {
    PARSEKIT_TOKEN_KIND_SYMBOL_TITLE = 14,
    PARSEKIT_TOKEN_KIND_SEMANTICPREDICATE,
    PARSEKIT_TOKEN_KIND_PIPE,
    PARSEKIT_TOKEN_KIND_AFTERKEY,
    PARSEKIT_TOKEN_KIND_CLOSE_CURLY,
    PARSEKIT_TOKEN_KIND_TILDE,
    PARSEKIT_TOKEN_KIND_START,
    PARSEKIT_TOKEN_KIND_COMMENT_TITLE,
    PARSEKIT_TOKEN_KIND_DISCARD,
    PARSEKIT_TOKEN_KIND_NUMBER_TITLE,
    PARSEKIT_TOKEN_KIND_ANY_TITLE,
    PARSEKIT_TOKEN_KIND_SEMI_COLON,
    PARSEKIT_TOKEN_KIND_S_TITLE,
    PARSEKIT_TOKEN_KIND_ACTION,
    PARSEKIT_TOKEN_KIND_EQUALS,
    PARSEKIT_TOKEN_KIND_AMPERSAND,
    PARSEKIT_TOKEN_KIND_PATTERNNOOPTS,
    PARSEKIT_TOKEN_KIND_PHRASEQUESTION,
    PARSEKIT_TOKEN_KIND_QUOTEDSTRING_TITLE,
    PARSEKIT_TOKEN_KIND_OPEN_PAREN,
    PARSEKIT_TOKEN_KIND_AT,
    PARSEKIT_TOKEN_KIND_PATTERNIGNORECASE,
    PARSEKIT_TOKEN_KIND_BEFOREKEY,
    PARSEKIT_TOKEN_KIND_EOF_TITLE,
    PARSEKIT_TOKEN_KIND_CLOSE_PAREN,
    PARSEKIT_TOKEN_KIND_PHRASESTAR,
    PARSEKIT_TOKEN_KIND_LETTER_TITLE,
    PARSEKIT_TOKEN_KIND_EMPTY_TITLE,
    PARSEKIT_TOKEN_KIND_PHRASEPLUS,
    PARSEKIT_TOKEN_KIND_OPEN_BRACKET,
    PARSEKIT_TOKEN_KIND_COMMA,
    PARSEKIT_TOKEN_KIND_SPECIFICCHAR_TITLE,
    PARSEKIT_TOKEN_KIND_MINUS,
    PARSEKIT_TOKEN_KIND_WORD_TITLE,
    PARSEKIT_TOKEN_KIND_CLOSE_BRACKET,
    PARSEKIT_TOKEN_KIND_CHAR_TITLE,
    PARSEKIT_TOKEN_KIND_DIGIT_TITLE,
    PARSEKIT_TOKEN_KIND_DELIMOPEN,
};

@interface ParseKitParser : PKSParser

@end

